module Approvable
  # A method related to approvers that is user facing
  # should be moved to VisibleApprovable because
  # of the fact that we use filtered versions of certain methods
  # such as approver_groups and target_project in presenters
  include ::VisibleApprovable

  def approval_needed?
    approvals_required&.nonzero?
  end

  def approved?
    approvals_left < 1
  end

  # Number of approvals remaining (excluding existing approvals) before the MR is
  # considered approved. If there are fewer potential approvers than approvals left,
  # users should either reduce the number of approvers on projects and/or merge
  # requests settings and/or allow MR authors to approve their own merge
  # requests (in case only one approval is needed).
  #
  def approvals_left
    approvals_left_count = approvals_required - approvals.size

    [approvals_left_count, 0].max
  end

  def approvals_required
    approvals_before_merge || target_project.approvals_before_merge
  end

  def approvals_before_merge
    return nil unless project&.feature_available?(:merge_request_approvers)

    super
  end

  # Even though this method is used in VisibleApprovable
  # we do not want to encounter a scenario where there are
  # no user approvers but there is one merge request group
  # approver that is not visible to the current_user,
  # which would make this method return false
  # when it should still report as overwritten.
  # To prevent this from happening, approvers_overwritten?
  # makes use of the unfiltered version of approver_groups so that
  # it always takes into account every approver
  # available
  #
  def approvers_overwritten?
    approvers.to_a.any? || approver_groups.to_a.any?
  end

  def can_approve?(user)
    return false unless user
    # The check below considers authors being able to approve the MR. That is,
    # they're included/excluded from that list accordingly.
    return true if approvers_left.include?(user)
    # We can safely unauthorize authors if it reaches this guard clause.
    return false if user == author
    return false unless user.can?(:update_merge_request, self)

    any_approver_allowed? && approvals.where(user: user).empty?
  end

  def has_approved?(user)
    return false unless user

    approved_by_users.include?(user)
  end

  # Once there are fewer approvers left in the list than approvals required or
  # there are no more approvals required
  # allow other project members to approve the MR.
  #
  def any_approver_allowed?
    remaining_approvals = approvals_left

    remaining_approvals.zero? || remaining_approvals > approvers_left.count
  end

  def authors_can_approve?
    target_project.merge_requests_author_approval?
  end

  def approver_ids=(value)
    ::Gitlab::Utils.ensure_array_from_string(value).each do |user_id|
      next if author && user_id == author.id

      approvers.find_or_initialize_by(user_id: user_id, target_id: id)
    end
  end

  def approver_group_ids=(value)
    ::Gitlab::Utils.ensure_array_from_string(value).each do |group_id|
      approver_groups.find_or_initialize_by(group_id: group_id, target_id: id)
    end
  end
end
