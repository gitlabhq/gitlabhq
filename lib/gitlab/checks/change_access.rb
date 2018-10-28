# frozen_string_literal: true

module Gitlab
  module Checks
    class ChangeAccess
      ERROR_MESSAGES = {
        push_code: 'You are not allowed to push code to this project.',
        delete_default_branch: 'The default branch of a project cannot be deleted.',
        force_push_protected_branch: 'You are not allowed to force push code to a protected branch on this project.',
        non_master_delete_protected_branch: 'You are not allowed to delete protected branches from this project. Only a project maintainer or owner can delete a protected branch.',
        non_web_delete_protected_branch: 'You can only delete protected branches using the web interface.',
        merge_protected_branch: 'You are not allowed to merge code into protected branches on this project.',
        push_protected_branch: 'You are not allowed to push code to protected branches on this project.',
        change_existing_tags: 'You are not allowed to change existing tags on this project.',
        update_protected_tag: 'Protected tags cannot be updated.',
        delete_protected_tag: 'Protected tags cannot be deleted.',
        create_protected_tag: 'You are not allowed to create this tag as it is protected.',
        lfs_objects_missing: 'LFS objects are missing. Ensure LFS is properly set up or try a manual "git lfs push --all".'
      }.freeze

      LOG_MESSAGES = {
        push_checks: "Checking if you are allowed to push...",
        delete_default_branch_check: "Checking if default branch is being deleted...",
        protected_branch_checks: "Checking if you are force pushing to a protected branch...",
        protected_branch_push_checks: "Checking if you are allowed to push to the protected branch...",
        protected_branch_deletion_checks: "Checking if you are allowed to delete the protected branch...",
        tag_checks: "Checking if you are allowed to change existing tags...",
        protected_tag_checks: "Checking if you are creating, updating or deleting a protected tag...",
        lfs_objects_exist_check: "Scanning repository for blobs stored in LFS and verifying their files have been uploaded to GitLab...",
        commits_check_file_paths_validation: "Validating commits' file paths...",
        commits_check: "Validating commit contents..."
      }.freeze

      attr_reader :user_access, :project, :skip_authorization, :skip_lfs_integrity_check, :protocol, :oldrev, :newrev, :ref, :branch_name, :tag_name, :logger

      def initialize(
        change, user_access:, project:, skip_authorization: false,
        skip_lfs_integrity_check: false, protocol:, logger:
      )
        @oldrev, @newrev, @ref = change.values_at(:oldrev, :newrev, :ref)
        @branch_name = Gitlab::Git.branch_name(@ref)
        @tag_name = Gitlab::Git.tag_name(@ref)
        @user_access = user_access
        @project = project
        @skip_authorization = skip_authorization
        @skip_lfs_integrity_check = skip_lfs_integrity_check
        @protocol = protocol

        @logger = logger
        @logger.append_message("Running checks for ref: #{@branch_name || @tag_name}")
      end

      def exec(skip_commits_check: false)
        return true if skip_authorization

        push_checks
        branch_checks
        tag_checks
        lfs_objects_exist_check unless skip_lfs_integrity_check
        commits_check unless skip_commits_check

        true
      end

      protected

      def push_checks
        logger.log_timed(LOG_MESSAGES[__method__]) do
          unless can_push?
            raise GitAccess::UnauthorizedError, ERROR_MESSAGES[:push_code]
          end
        end
      end

      def branch_checks
        return unless branch_name

        logger.log_timed(LOG_MESSAGES[:delete_default_branch_check]) do
          if deletion? && branch_name == project.default_branch
            raise GitAccess::UnauthorizedError, ERROR_MESSAGES[:delete_default_branch]
          end
        end

        protected_branch_checks
      end

      def protected_branch_checks
        logger.log_timed(LOG_MESSAGES[__method__]) do
          return unless ProtectedBranch.protected?(project, branch_name) # rubocop:disable Cop/AvoidReturnFromBlocks

          if forced_push?
            raise GitAccess::UnauthorizedError, ERROR_MESSAGES[:force_push_protected_branch]
          end
        end

        if deletion?
          protected_branch_deletion_checks
        else
          protected_branch_push_checks
        end
      end

      def protected_branch_deletion_checks
        logger.log_timed(LOG_MESSAGES[__method__]) do
          unless user_access.can_delete_branch?(branch_name)
            raise GitAccess::UnauthorizedError, ERROR_MESSAGES[:non_master_delete_protected_branch]
          end

          unless updated_from_web?
            raise GitAccess::UnauthorizedError, ERROR_MESSAGES[:non_web_delete_protected_branch]
          end
        end
      end

      def protected_branch_push_checks
        logger.log_timed(LOG_MESSAGES[__method__]) do
          if matching_merge_request?
            unless user_access.can_merge_to_branch?(branch_name) || user_access.can_push_to_branch?(branch_name)
              raise GitAccess::UnauthorizedError, ERROR_MESSAGES[:merge_protected_branch]
            end
          else
            unless user_access.can_push_to_branch?(branch_name)
              raise GitAccess::UnauthorizedError, push_to_protected_branch_rejected_message
            end
          end
        end
      end

      def tag_checks
        return unless tag_name

        logger.log_timed(LOG_MESSAGES[__method__]) do
          if tag_exists? && user_access.cannot_do_action?(:admin_project)
            raise GitAccess::UnauthorizedError, ERROR_MESSAGES[:change_existing_tags]
          end
        end

        protected_tag_checks
      end

      def protected_tag_checks
        logger.log_timed(LOG_MESSAGES[__method__]) do
          return unless ProtectedTag.protected?(project, tag_name) # rubocop:disable Cop/AvoidReturnFromBlocks

          raise(GitAccess::UnauthorizedError, ERROR_MESSAGES[:update_protected_tag]) if update?
          raise(GitAccess::UnauthorizedError, ERROR_MESSAGES[:delete_protected_tag]) if deletion?

          unless user_access.can_create_tag?(tag_name)
            raise GitAccess::UnauthorizedError, ERROR_MESSAGES[:create_protected_tag]
          end
        end
      end

      def commits_check
        return if deletion? || newrev.nil?
        return unless should_run_commit_validations?

        logger.log_timed(LOG_MESSAGES[__method__]) do
          # n+1: https://gitlab.com/gitlab-org/gitlab-ee/issues/3593
          ::Gitlab::GitalyClient.allow_n_plus_1_calls do
            commits.each do |commit|
              logger.check_timeout_reached

              commit_check.validate(commit, validations_for_commit(commit))
            end
          end
        end

        logger.log_timed(LOG_MESSAGES[:commits_check_file_paths_validation]) do
          commit_check.validate_file_paths
        end
      end

      # Method overwritten in EE to inject custom validations
      def validations_for_commit(_)
        []
      end

      private

      def push_to_protected_branch_rejected_message
        if project.empty_repo?
          empty_project_push_message
        else
          ERROR_MESSAGES[:push_protected_branch]
        end
      end

      def empty_project_push_message
        <<~MESSAGE

        A default branch (e.g. master) does not yet exist for #{project.full_path}
        Ask a project Owner or Maintainer to create a default branch:

          #{project_members_url}

        MESSAGE
      end

      def project_members_url
        Gitlab::Routing.url_helpers.project_project_members_url(project)
      end

      def should_run_commit_validations?
        commit_check.validate_lfs_file_locks?
      end

      def updated_from_web?
        protocol == 'web'
      end

      def tag_exists?
        project.repository.tag_exists?(tag_name)
      end

      def forced_push?
        Gitlab::Checks::ForcePush.force_push?(project, oldrev, newrev)
      end

      def update?
        !Gitlab::Git.blank_ref?(oldrev) && !deletion?
      end

      def deletion?
        Gitlab::Git.blank_ref?(newrev)
      end

      def matching_merge_request?
        Checks::MatchingMergeRequest.new(newrev, branch_name, project).match?
      end

      def lfs_objects_exist_check
        logger.log_timed(LOG_MESSAGES[__method__]) do
          lfs_check = Checks::LfsIntegrity.new(project, newrev, logger.time_left)

          if lfs_check.objects_missing?
            raise GitAccess::UnauthorizedError, ERROR_MESSAGES[:lfs_objects_missing]
          end
        end
      end

      def commit_check
        @commit_check ||= Gitlab::Checks::CommitCheck.new(project, user_access.user, newrev, oldrev)
      end

      def commits
        @commits ||= project.repository.new_commits(newrev)
      end

      def can_push?
        user_access.can_do_action?(:push_code) ||
          user_access.can_push_to_branch?(branch_name)
      end
    end
  end
end
