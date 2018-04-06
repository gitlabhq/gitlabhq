# Concern that encapsulates logic to remove all
# approvers in a project that were not added during
# the current transaction
module CleanupApprovers
  extend ActiveSupport::Concern

  private

  def cleanup_approvers(target, reload: false)
    target.approvers.where.not(user_id: params[:approver_ids]).destroy_all
    target.approver_groups.where.not(group_id: params[:approver_group_ids]).destroy_all

    # If the target already has `approvers` and/or `approver_groups` loaded then we need to
    # force a reload in order to not return stale information after the destroys above
    if reload
      target.approvers.reload
      target.approver_groups.reload
    end

    target
  end
end
