module Gitlab
  module Checks
    class ChangeAccess
      include PathLocksHelper
      attr_reader :user_access, :project

      def initialize(change, user_access:, project:)
        @oldrev, @newrev, @ref = change.values_at(:oldrev, :newrev, :ref)
        @branch_name = Gitlab::Git.branch_name(@ref)
        @user_access = user_access
        @project = project
      end

      def exec
        error = push_checks || tag_checks || protected_branch_checks || push_rule_check

        if error
          GitAccessStatus.new(false, error)
        else
          GitAccessStatus.new(true)
        end
      end

      protected

      def protected_branch_checks
        return unless @branch_name
        return unless project.protected_branch?(@branch_name)

        if forced_push? && user_access.cannot_do_action?(:force_push_code_to_protected_branches)
          return "You are not allowed to force push code to a protected branch on this project."
        elsif Gitlab::Git.blank_ref?(@newrev) && user_access.cannot_do_action?(:remove_protected_branches)
          return "You are not allowed to delete protected branches from this project."
        end

        if matching_merge_request?
          if user_access.can_merge_to_branch?(@branch_name) || user_access.can_push_to_branch?(@branch_name)
            return
          else
            "You are not allowed to merge code into protected branches on this project."
          end
        else
          if user_access.can_push_to_branch?(@branch_name)
            return
          else
            "You are not allowed to push code to protected branches on this project."
          end
        end
      end

      def tag_checks
        tag_ref = Gitlab::Git.tag_name(@ref)

        if tag_ref && protected_tag?(tag_ref) && user_access.cannot_do_action?(:admin_project)
          "You are not allowed to change existing tags on this project."
        end
      end

      def push_checks
        if user_access.cannot_do_action?(:push_code)
          "You are not allowed to push code to this project."
        end
      end

      private

      def protected_tag?(tag_name)
        project.repository.tag_exists?(tag_name)
      end

      def forced_push?
        Gitlab::Checks::ForcePush.force_push?(@project, @oldrev, @newrev)
      end

      def matching_merge_request?
        Checks::MatchingMergeRequest.new(@newrev, @branch_name, @project).match?
      end

      def push_rule_check
        return unless @newrev && @oldrev

        push_rule = project.push_rule

        # Prevent tag removal
        if Gitlab::Git.tag_name(@ref)
          if push_rule.try(:deny_delete_tag) && protected_tag?(Gitlab::Git.tag_name(@ref)) && Gitlab::Git.blank_ref?(@newrev)
            return  "You can not delete a tag"
          end
        else
          commit_validation = push_rule.try(:commit_validation?)

          # if newrev is blank, the branch was deleted
          return if Gitlab::Git.blank_ref?(@newrev) ||
            !(commit_validation || validate_path_locks?)

          commits.each do |commit|
            next if commit_from_annex_sync?(commit.safe_message)

            if commit_validation
              error = check_commit(commit, push_rule)
              return error if error
            end

            if error = check_commit_diff(commit, push_rule)
              return error
            end
          end
        end

        nil
      end

      # If commit does not pass push rule validation the whole push should be rejected.
      # This method should return nil if no error found or status object if there are some errors.
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

        # Check whether author is a GitLab member
        if push_rule.member_check
          unless User.existing_member?(commit.author_email.downcase)
            return "Author '#{commit.author_email}' is not a member of team"
          end

          if commit.author_email.casecmp(commit.committer_email) == -1
            unless User.existing_member?(commit.committer_email.downcase)
              return "Committer '#{commit.committer_email}' is not a member of team"
            end
          end
        end

        nil
      end

      def check_commit_diff(commit, push_rule)
        validations = validations_for_commit(commit, push_rule)

        return if validations.empty?

        commit.raw_diffs(deltas_only: true).each do |diff|
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
        @validate_path_locks ||= license_allows_file_locks? &&
          project.path_locks.any? && @newrev && @oldrev &&
          project.default_branch == @branch_name # locks protect default branch only
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
        project.repository.new_commits(@newrev)
      end

      def commit_from_annex_sync?(commit_message)
        return false unless Gitlab.config.gitlab_shell.git_annex_enabled

        # Commit message starting with <git-annex in > so avoid push rules on this
        commit_message.start_with?('git-annex in')
      end
    end
  end
end
