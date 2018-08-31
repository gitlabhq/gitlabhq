module Approvable
  include Gitlab::Utils::StrongMemoize

  def requires_approve?
    # keep until UI changes implemented
    true
  end

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

  # Users in the list of approvers who have not already approved this MR.
  #
  def approvers_left
    strong_memoize(:approvers_left) do
      User.where(id: all_approvers_including_groups.map(&:id)).where.not(id: approved_by_users.select(:id))
    end
  end

  # The list of approvers from either this MR (if they've been set on the MR) or the
  # target project. Excludes the author if 'self-approval' isn't explicitly
  # enabled on project settings.
  #
  # Before a merge request has been created, author will be nil, so pass the current user
  # on the MR create page.
  #
  def overall_approvers
    approvers_relation = approvers_overwritten? ? approvers : target_project.approvers

    if author && !authors_can_approve?
      approvers_relation = approvers_relation.where.not(user_id: author.id)
    end

    approvers_relation.includes(:user)
  end

  def overall_approver_groups
    approvers_overwritten? ? approver_groups : target_project.approver_groups
  end

  def all_approvers_including_groups
    strong_memoize(:all_approvers_including_groups) do
      approvers = []

      # Approvers from direct assignment
      approvers << approvers_from_users

      approvers << approvers_from_groups

      approvers.flatten
    end
  end

  def approvers_from_users
    overall_approvers.map(&:user)
  end

  def approvers_from_groups
    group_approvers = []

    overall_approver_groups.each do |approver_group|
      group_approvers << approver_group.users
    end

    group_approvers.flatten!

    group_approvers.delete(author) unless authors_can_approve?

    group_approvers
  end

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

  def reset_approval_cache!
    approvals(true)
    approved_by_users(true)

    clear_memoization(:approvers_left)
    clear_memoization(:all_approvers_including_groups)
  end
end
