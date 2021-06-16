# frozen_string_literal: true

module Gitlab
  module Checks
    class BranchCheck < BaseSingleChecker
      ERROR_MESSAGES = {
        delete_default_branch: 'The default branch of a project cannot be deleted.',
        force_push_protected_branch: 'You are not allowed to force push code to a protected branch on this project.',
        non_master_delete_protected_branch: 'You are not allowed to delete protected branches from this project. Only a project maintainer or owner can delete a protected branch.',
        non_web_delete_protected_branch: 'You can only delete protected branches using the web interface.',
        merge_protected_branch: 'You are not allowed to merge code into protected branches on this project.',
        push_protected_branch: 'You are not allowed to push code to protected branches on this project.',
        create_protected_branch: 'You are not allowed to create protected branches on this project.',
        invalid_commit_create_protected_branch: 'You can only use an existing protected branch ref as the basis of a new protected branch.',
        non_web_create_protected_branch: 'You can only create protected branches using the web interface and API.',
        prohibited_hex_branch_name: 'You cannot create a branch with a 40-character hexadecimal branch name.'
      }.freeze

      LOG_MESSAGES = {
        delete_default_branch_check: "Checking if default branch is being deleted...",
        protected_branch_checks: "Checking if you are force pushing to a protected branch...",
        protected_branch_push_checks: "Checking if you are allowed to push to the protected branch...",
        protected_branch_creation_checks: "Checking if you are allowed to create a protected branch...",
        protected_branch_deletion_checks: "Checking if you are allowed to delete the protected branch..."
      }.freeze

      def validate!
        return unless branch_name

        logger.log_timed(LOG_MESSAGES[:delete_default_branch_check]) do
          if deletion? && branch_name == project.default_branch
            raise GitAccess::ForbiddenError, ERROR_MESSAGES[:delete_default_branch]
          end
        end

        prohibited_branch_checks
        protected_branch_checks
      end

      private

      def prohibited_branch_checks
        return unless Feature.enabled?(:prohibit_hexadecimal_branch_names, project, default_enabled: true)

        if branch_name =~ /\A\h{40}\z/
          raise GitAccess::ForbiddenError, ERROR_MESSAGES[:prohibited_hex_branch_name]
        end
      end

      def protected_branch_checks
        logger.log_timed(LOG_MESSAGES[:protected_branch_checks]) do
          return unless ProtectedBranch.protected?(project, branch_name) # rubocop:disable Cop/AvoidReturnFromBlocks

          if forced_push? && !ProtectedBranch.allow_force_push?(project, branch_name)
            raise GitAccess::ForbiddenError, ERROR_MESSAGES[:force_push_protected_branch]
          end
        end

        if project.empty_repo?
          protected_branch_push_checks
        elsif creation?
          protected_branch_creation_checks
        elsif deletion?
          protected_branch_deletion_checks
        else
          protected_branch_push_checks
        end
      end

      def protected_branch_creation_checks
        logger.log_timed(LOG_MESSAGES[:protected_branch_creation_checks]) do
          break if user_access.can_push_to_branch?(branch_name)

          unless user_access.can_merge_to_branch?(branch_name)
            raise GitAccess::ForbiddenError, ERROR_MESSAGES[:create_protected_branch]
          end

          unless safe_commit_for_new_protected_branch?
            raise GitAccess::ForbiddenError, ERROR_MESSAGES[:invalid_commit_create_protected_branch]
          end

          unless updated_from_web?
            raise GitAccess::ForbiddenError, ERROR_MESSAGES[:non_web_create_protected_branch]
          end
        end
      end

      def protected_branch_deletion_checks
        logger.log_timed(LOG_MESSAGES[:protected_branch_deletion_checks]) do
          unless user_access.can_delete_branch?(branch_name)
            raise GitAccess::ForbiddenError, ERROR_MESSAGES[:non_master_delete_protected_branch]
          end

          unless updated_from_web?
            raise GitAccess::ForbiddenError, ERROR_MESSAGES[:non_web_delete_protected_branch]
          end
        end
      end

      def protected_branch_push_checks
        logger.log_timed(LOG_MESSAGES[:protected_branch_push_checks]) do
          if matching_merge_request?
            unless user_access.can_merge_to_branch?(branch_name) || user_access.can_push_to_branch?(branch_name)
              raise GitAccess::ForbiddenError, ERROR_MESSAGES[:merge_protected_branch]
            end
          else
            unless user_access.can_push_to_branch?(branch_name)
              raise GitAccess::ForbiddenError, push_to_protected_branch_rejected_message
            end
          end
        end
      end

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

      def matching_merge_request?
        Checks::MatchingMergeRequest.new(newrev, branch_name, project).match?
      end

      def forced_push?
        Gitlab::Checks::ForcePush.force_push?(project, oldrev, newrev)
      end

      def safe_commit_for_new_protected_branch?
        ProtectedBranch.any_protected?(project, project.repository.branch_names_contains_sha(newrev))
      end
    end
  end
end
