module EE
  module Gitlab
    module Checks
      module ChangeAccess
        extend ActiveSupport::Concern
        extend ::Gitlab::Utils::Override
        include PathLocksHelper
        include ::Gitlab::Utils::StrongMemoize

        ERROR_MESSAGES = {
          push_rule_branch_name: "Branch name does not follow the pattern '%{branch_name_regex}'",
          push_rule_committer_not_verified: "Comitter email '%{commiter_email}' is not verified.",
          push_rule_committer_not_allowed: "You cannot push commits for '%{committer_email}'. You can only push commits that were committed with one of your own verified emails."
        }.freeze

        override :exec
        def exec
          return true if skip_authorization

          super

          push_rule_check

          true
        end

        private

        def push_rule_check
          return unless newrev && oldrev && project.feature_available?(:push_rules)

          push_rule = project.push_rule

          if tag_name
            push_rule_tag_check(push_rule)
          else
            push_rule_branch_check(push_rule)
          end
        end

        def push_rule_tag_check(push_rule)
          if tag_deletion_denied_by_push_rule?(push_rule)
            raise ::Gitlab::GitAccess::UnauthorizedError, 'You cannot delete a tag'
          end
        end

        def push_rule_branch_check(push_rule)
          unless branch_name_allowed_by_push_rule?(push_rule)
            message = ERROR_MESSAGES[:push_rule_branch_name] % { branch_name_regex: push_rule.branch_name_regex }
            raise ::Gitlab::GitAccess::UnauthorizedError.new(message)
          end

          commit_validation = push_rule.try(:commit_validation?)
          # if newrev is blank, the branch was deleted
          return if deletion? || !(commit_validation || validate_path_locks?)

          # n+1: https://gitlab.com/gitlab-org/gitlab-ee/issues/3593
          ::Gitlab::GitalyClient.allow_n_plus_1_calls do
            commits.each do |commit|
              push_rule_commit_check(commit, push_rule)
            end
          end
        rescue ::PushRule::MatchError => e
          raise ::Gitlab::GitAccess::UnauthorizedError, e.message
        end

        def branch_name_allowed_by_push_rule?(push_rule)
          return true if skip_branch_name_push_rule?(push_rule)

          push_rule.branch_name_allowed?(branch_name)
        end

        def skip_branch_name_push_rule?(push_rule)
          push_rule.nil? ||
            deletion? ||
            branch_name.blank? ||
            branch_name == project.default_branch
        end

        def tag_deletion_denied_by_push_rule?(push_rule)
          push_rule.try(:deny_delete_tag) &&
            !updated_from_web? &&
            deletion? &&
            tag_exists?
        end

        def push_rule_commit_check(commit, push_rule)
          if push_rule.try(:commit_validation?)
            error = check_commit(commit, push_rule)
            raise ::Gitlab::GitAccess::UnauthorizedError, error if error
          end

          if error = check_commit_diff(commit, push_rule)
            raise ::Gitlab::GitAccess::UnauthorizedError, error
          end
        end

        # If commit does not pass push rule validation the whole push should be rejected.
        # This method should return nil if no error found or a string if error.
        # In case of errors - all other checks will be canceled and push will be rejected.
        def check_commit(commit, push_rule)
          unless push_rule.commit_message_allowed?(commit.safe_message)
            return "Commit message does not follow the pattern '#{push_rule.commit_message_regex}'"
          end

          unless push_rule.author_email_allowed?(commit.committer_email)
            return "Committer's email '#{commit.committer_email}' does not follow the pattern '#{push_rule.author_email_regex}'"
          end

          unless push_rule.author_email_allowed?(commit.author_email)
            return "Author's email '#{commit.author_email}' does not follow the pattern '#{push_rule.author_email_regex}'"
          end

          committer_error_message = committer_check(commit, push_rule)
          return committer_error_message if committer_error_message

          if !updated_from_web? && !push_rule.commit_signature_allowed?(commit)
            return "Commit must be signed with a GPG key"
          end

          # Check whether author is a GitLab member
          if push_rule.member_check
            unless ::User.existing_member?(commit.author_email.downcase)
              return "Author '#{commit.author_email}' is not a member of team"
            end

            if commit.author_email.casecmp(commit.committer_email) == -1
              unless ::User.existing_member?(commit.committer_email.downcase)
                return "Committer '#{commit.committer_email}' is not a member of team"
              end
            end
          end

          nil
        end

        def committer_check(commit, push_rule)
          unless push_rule.committer_allowed?(commit.committer_email, user_access.user)
            committer_is_current_user = commit.committer == user_access.user

            if committer_is_current_user && !commit.committer.verified_email?(commit.committer_email)
              ERROR_MESSAGES[:push_rule_committer_not_verified] % { committer_email: commit.committer_email }
            else
              ERROR_MESSAGES[:push_rule_committer_not_allowed] % { committer_email: commit.committer_email }
            end
          end
        end

        def check_commit_diff(commit, push_rule)
          validations = validations_for_commit(commit, push_rule)

          return if validations.empty?

          commit.raw_deltas.each do |diff|
            validations.each do |validation|
              if error = validation.call(diff)
                return error
              end
            end
          end

          nil
        end

        def validations_for_commit(commit, push_rule)
          validations = base_validations

          return validations unless push_rule

          validations << file_name_validation(push_rule)

          if push_rule.max_file_size > 0
            validations << file_size_validation(commit, push_rule.max_file_size)
          end

          validations
        end

        def base_validations
          validate_path_locks? ? [path_locks_validation] : []
        end

        def validate_path_locks?
          strong_memoize(:validate_path_locks) do
            project.feature_available?(:file_locks) &&
              project.path_locks.any? && newrev && oldrev &&
              project.default_branch == branch_name # locks protect default branch only
          end
        end

        def path_locks_validation
          lambda do |diff|
            path = diff.new_path || diff.old_path

            lock_info = project.find_path_lock(path)

            if lock_info && lock_info.user != user_access.user
              return "The path '#{lock_info.path}' is locked by #{lock_info.user.name}"
            end
          end
        end

        def file_name_validation(push_rule)
          lambda do |diff|
            if (diff.renamed_file || diff.new_file) && blacklisted_regex = push_rule.filename_blacklisted?(diff.new_path)
              return nil unless blacklisted_regex.present?

              "File name #{diff.new_path} was blacklisted by the pattern #{blacklisted_regex}."
            end
          end
        end

        def file_size_validation(commit, max_file_size)
          lambda do |diff|
            return if diff.deleted_file

            blob = project.repository.blob_at(commit.id, diff.new_path)
            if blob && blob.size && blob.size > max_file_size.megabytes
              return "File #{diff.new_path.inspect} is larger than the allowed size of #{max_file_size} MB"
            end
          end
        end

        def commits
          project.repository.new_commits(newrev)
        end
      end
    end
  end
end
