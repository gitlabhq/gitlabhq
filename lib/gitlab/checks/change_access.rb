module Gitlab
  module Checks
    class ChangeAccess
      include PathLocksHelper

      ERROR_MESSAGES = {
        push_code: 'You are not allowed to push code to this project.',
        delete_default_branch: 'The default branch of a project cannot be deleted.',
        force_push_protected_branch: 'You are not allowed to force push code to a protected branch on this project.',
        non_master_delete_protected_branch: 'You are not allowed to delete protected branches from this project. Only a project master or owner can delete a protected branch.',
        non_web_delete_protected_branch: 'You can only delete protected branches using the web interface.',
        merge_protected_branch: 'You are not allowed to merge code into protected branches on this project.',
        push_protected_branch: 'You are not allowed to push code to protected branches on this project.',
        change_existing_tags: 'You are not allowed to change existing tags on this project.',
        update_protected_tag: 'Protected tags cannot be updated.',
        delete_protected_tag: 'Protected tags cannot be deleted.',
        create_protected_tag: 'You are not allowed to create this tag as it is protected.'
      }.freeze

      # protocol is currently used only in EE
      attr_reader :user_access, :project, :skip_authorization, :protocol

      def initialize(
        change, user_access:, project:, skip_authorization: false,
        protocol:
      )
        @oldrev, @newrev, @ref = change.values_at(:oldrev, :newrev, :ref)
        @branch_name = Gitlab::Git.branch_name(@ref)
        @tag_name = Gitlab::Git.tag_name(@ref)
        @user_access = user_access
        @project = project
        @skip_authorization = skip_authorization
        @protocol = protocol
      end

      def exec
        return true if skip_authorization

        push_checks
        branch_checks
        tag_checks
        push_rule_check

        true
      end

      protected

      def push_checks
        if user_access.cannot_do_action?(:push_code)
          raise GitAccess::UnauthorizedError, ERROR_MESSAGES[:push_code]
        end
      end

      def branch_checks
        return unless @branch_name

        if deletion? && @branch_name == project.default_branch
          raise GitAccess::UnauthorizedError, ERROR_MESSAGES[:delete_default_branch]
        end

        protected_branch_checks
      end

      def protected_branch_checks
        return unless ProtectedBranch.protected?(project, @branch_name)

        if forced_push?
          raise GitAccess::UnauthorizedError, ERROR_MESSAGES[:force_push_protected_branch]
        end

        if deletion?
          protected_branch_deletion_checks
        else
          protected_branch_push_checks
        end
      end

      def protected_branch_deletion_checks
        unless user_access.can_delete_branch?(@branch_name)
          raise GitAccess::UnauthorizedError, ERROR_MESSAGES[:non_master_delete_protected_branch]
        end

        unless protocol == 'web'
          raise GitAccess::UnauthorizedError, ERROR_MESSAGES[:non_web_delete_protected_branch]
        end
      end

      def protected_branch_push_checks
        if matching_merge_request?
          unless user_access.can_merge_to_branch?(@branch_name) || user_access.can_push_to_branch?(@branch_name)
            raise GitAccess::UnauthorizedError, ERROR_MESSAGES[:merge_protected_branch]
          end
        else
          unless user_access.can_push_to_branch?(@branch_name)
            raise GitAccess::UnauthorizedError, ERROR_MESSAGES[:push_protected_branch]
          end
        end
      end

      def tag_checks
        return unless @tag_name

        if tag_exists? && user_access.cannot_do_action?(:admin_project)
          raise GitAccess::UnauthorizedError, ERROR_MESSAGES[:change_existing_tags]
        end

        protected_tag_checks
      end

      def protected_tag_checks
        return unless ProtectedTag.protected?(project, @tag_name)

        raise(GitAccess::UnauthorizedError, ERROR_MESSAGES[:update_protected_tag]) if update?
        raise(GitAccess::UnauthorizedError, ERROR_MESSAGES[:delete_protected_tag]) if deletion?

        unless user_access.can_create_tag?(@tag_name)
          raise GitAccess::UnauthorizedError, ERROR_MESSAGES[:create_protected_tag]
        end
      end

      private

      def tag_exists?
        project.repository.tag_exists?(@tag_name)
      end

      def forced_push?
        Gitlab::Checks::ForcePush.force_push?(@project, @oldrev, @newrev)
      end

      def update?
        !Gitlab::Git.blank_ref?(@oldrev) && !deletion?
      end

      def deletion?
        Gitlab::Git.blank_ref?(@newrev)
      end

      def matching_merge_request?
        Checks::MatchingMergeRequest.new(@newrev, @branch_name, @project).match?
      end

      def push_rule_check
        return unless @newrev && @oldrev && project.feature_available?(:push_rules)

        push_rule = project.push_rule

        # Prevent tag removal
        if @tag_name
          if tag_deletion_denied_by_push_rule?(push_rule)
            raise GitAccess::UnauthorizedError, 'You cannot delete a tag'
          end
        else
          commit_validation = push_rule.try(:commit_validation?)

          # if newrev is blank, the branch was deleted
          return if deletion? || !(commit_validation || validate_path_locks?)

          commits.each do |commit|
            if commit_validation
              error = check_commit(commit, push_rule)
              raise GitAccess::UnauthorizedError, error if error
            end

            if error = check_commit_diff(commit, push_rule)
              raise GitAccess::UnauthorizedError, error
            end
          end
        end
      end

      def tag_deletion_denied_by_push_rule?(push_rule)
        push_rule.try(:deny_delete_tag) &&
          protocol != 'web' &&
          deletion? &&
          tag_exists?
      end

      # If commit does not pass push rule validation the whole push should be rejected.
      # This method should return nil if no error found or a string if error.
      # In case of errors - all other checks will be canceled and push will be rejected.
      def check_commit(commit, push_rule)
        unless push_rule.commit_message_allowed?(commit.safe_message)
          return "Commit message does not follow the pattern '#{push_rule.commit_message_regex}'"
        end

        if @branch_name && !push_rule.branch_name_allowed?(@branch_name)
          return "Branch name does not follow the pattern '#{push_rule.branch_name_regex}'"
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
        @validate_path_locks ||= @project.feature_available?(:file_locks) &&
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
    end
  end
end
