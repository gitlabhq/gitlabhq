module EE
  module MergeRequestPresenter
    include ::VisibleApprovable

    def approvals_path
      if requires_approve?
        approvals_project_merge_request_path(project, merge_request)
      end
    end

    def target_project
      merge_request.target_project.present(current_user: current_user)
    end

    def approver_groups
      ::ApproverGroup.filtered_approver_groups(merge_request.approver_groups, current_user)
    end
  end
end
