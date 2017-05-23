module Gitlab
  module Checks
    class ChangeAccess
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
        return GitAccessStatus.new(true) if skip_authorization

        error = push_checks || branch_checks || tag_checks

        if error
          GitAccessStatus.new(false, error)
        else
          GitAccessStatus.new(true)
        end
      end

      protected

      def push_checks
        if user_access.cannot_do_action?(:push_code)
          "You are not allowed to push code to this project."
        end
      end

      def branch_checks
        return unless @branch_name

        if deletion? && @branch_name == project.default_branch
          return "The default branch of a project cannot be deleted."
        end

        protected_branch_checks
      end

      def protected_branch_checks
        return unless ProtectedBranch.protected?(project, @branch_name)

        if forced_push?
          return "You are not allowed to force push code to a protected branch on this project."
        end

        if deletion?
          protected_branch_deletion_checks
        else
          protected_branch_push_checks
        end
      end

      def protected_branch_deletion_checks
        unless user_access.can_delete_branch?(@branch_name)
          return 'You are not allowed to delete protected branches from this project. Only a project master or owner can delete a protected branch.'
        end

        unless protocol == 'web'
          'You can only delete protected branches using the web interface.'
        end
      end

      def protected_branch_push_checks
        if matching_merge_request?
          unless user_access.can_merge_to_branch?(@branch_name) || user_access.can_push_to_branch?(@branch_name)
            "You are not allowed to merge code into protected branches on this project."
          end
        else
          unless user_access.can_push_to_branch?(@branch_name)
            "You are not allowed to push code to protected branches on this project."
          end
        end
      end

      def tag_checks
        return unless @tag_name

        if tag_exists? && user_access.cannot_do_action?(:admin_project)
          return "You are not allowed to change existing tags on this project."
        end

        protected_tag_checks
      end

      def protected_tag_checks
        return unless ProtectedTag.protected?(project, @tag_name)

        return "Protected tags cannot be updated." if update?
        return "Protected tags cannot be deleted." if deletion?

        unless user_access.can_create_tag?(@tag_name)
          return "You are not allowed to create this tag as it is protected."
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
    end
  end
end
