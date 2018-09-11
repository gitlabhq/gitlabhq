module EE
  module MergeRequests
    module UpdateService
      extend ::Gitlab::Utils::Override

      include CleanupApprovers

      override :execute
      def execute(merge_request)
        should_remove_old_approvers = params.delete(:remove_old_approvers)
        old_approvers = merge_request.overall_approvers.to_a

        merge_request = super(merge_request)

        new_approvers = merge_request.overall_approvers.to_a - old_approvers

        if new_approvers.any?
          todo_service.add_merge_request_approvers(merge_request, new_approvers)
          notification_service.add_merge_request_approvers(merge_request, new_approvers, current_user)
        end

        if should_remove_old_approvers && merge_request.valid?
          cleanup_approvers(merge_request, reload: true)
        end

        merge_request
      end

      override :create_branch_change_note
      def create_branch_change_note(merge_request, branch_type, old_branch, new_branch)
        super

        reset_approvals(merge_request)
      end

      private

      def reset_approvals(merge_request)
        target_project = merge_request.target_project

        merge_request.approvals.delete_all if target_project.reset_approvals_on_push
      end
    end
  end
end
