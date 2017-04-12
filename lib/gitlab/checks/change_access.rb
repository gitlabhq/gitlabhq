module Gitlab
  module Checks
    class ChangeAccess
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
        error = push_checks || tag_checks || protected_branch_checks

        if error
          GitAccessStatus.new(false, error)
        else
          GitAccessStatus.new(true)
        end
      end

      protected

      def protected_branch_checks
        return if skip_authorization
        return unless @branch_name
        return unless ProtectedBranch.protected?(project, @branch_name)

        if forced_push?
          return "You are not allowed to force push code to a protected branch on this project."
        elsif deletion?
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
        return if skip_authorization

        return unless @tag_name

        if tag_exists? && user_access.cannot_do_action?(:admin_project)
          return "You are not allowed to change existing tags on this project."
        end

        protected_tag_checks
      end

      def protected_tag_checks
        return unless tag_protected?
        return "Protected tags cannot be updated." if update?
        return "Protected tags cannot be deleted." if deletion?

        unless user_access.can_create_tag?(@tag_name)
          return "You are not allowed to create this tag as it is protected."
        end
      end

      def tag_protected?
        ProtectedTag.protected?(project, @tag_name)
      end

      def push_checks
        return if skip_authorization

        if user_access.cannot_do_action?(:push_code)
          "You are not allowed to push code to this project."
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
