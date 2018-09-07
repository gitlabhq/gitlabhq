module EE
  module MergeRequestPresenter
    include ::Gitlab::Utils::StrongMemoize

    def approvals_path
      if requires_approve?
        approvals_project_merge_request_path(project, merge_request)
      end
    end

    def all_approvers_including_groups
      strong_memoize(:all_approvers_including_groups) do
        approvers = []

        # approvers from direct assignment
        approvers << merge_request.approvers_from_users
        approvers << approvers_from_groups

        approvers.flatten
      end
    end

    def overall_approver_groups
      if approvers_overwritten?
        approver_groups
      else
        merge_request.target_project.present(current_user: current_user).approver_groups
      end
    end

    def approvers_overwritten?
      merge_request.approvers.to_a.any? || approver_groups.to_a.any?
    end

    private

    def approvers_from_groups
      overall_approver_groups.flat_map(&:users) - [merge_request.author]
    end

    def approver_groups
      ::ApproverGroup.filtered_approver_groups(merge_request.approver_groups, current_user)
    end
  end
end
