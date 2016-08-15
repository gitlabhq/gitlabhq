module Gitlab
  module Checks
    class ChangeAccess
      attr_reader :user_access, :project

      def initialize(change, user_access:, project:)
        @oldrev, @newrev, @ref = change.values_at(:oldrev, :newrev, :ref)
        @branch_name = Gitlab::Git.branch_name(@ref)
        @user_access = user_access
        @project = project
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
    end
  end
end
