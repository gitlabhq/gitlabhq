# Finders::Issues class
#
# Used to filter Issues collections by set of params
#
# Arguments:
#   current_user - which user use
#   params:
#     scope: 'created-by-me' or 'assigned-to-me' or 'all'
#     state: 'open' or 'closed' or 'all'
#     group_id: integer
#     project_id: integer
#     milestone_title: string
#     assignee_id: integer
#     search: string
#     label_name: string
#     sort: string
#     my_reaction_emoji: string
#     public_only: boolean
#     due_date: date or '0', '', 'overdue', 'week', or 'month'
#     created_after: datetime
#     created_before: datetime
#     updated_after: datetime
#     updated_before: datetime
#
class IssuesFinder < IssuableFinder
  prepend EE::IssuesFinder

  CONFIDENTIAL_ACCESS_LEVEL = Gitlab::Access::REPORTER

  def self.scalar_params
    @scalar_params ||= super + [:due_date]
  end

  def klass
    Issue.includes(:author)
  end

  def with_confidentiality_access_check
    return Issue.all if user_can_see_all_confidential_issues?
    return Issue.where('issues.confidential IS NOT TRUE') if user_cannot_see_confidential_issues?

    Issue.where('
      issues.confidential IS NOT TRUE
      OR (issues.confidential = TRUE
        AND (issues.author_id = :user_id
          OR EXISTS (SELECT TRUE FROM issue_assignees WHERE user_id = :user_id AND issue_id = issues.id)
          OR issues.project_id IN(:project_ids)))',
      user_id: current_user.id,
      project_ids: current_user.authorized_projects(CONFIDENTIAL_ACCESS_LEVEL).select(:id))
  end

  private

  def init_collection
    if public_only?
      Issue.public_only
    else
      with_confidentiality_access_check
    end
  end

  def public_only?
    params.fetch(:public_only, false)
  end

  def filter_items(items)
    by_due_date(super)
  end

  def by_due_date(items)
    if due_date?
      if filter_by_no_due_date?
        items = items.without_due_date
      elsif filter_by_overdue?
        items = items.due_before(Date.today)
      elsif filter_by_due_this_week?
        items = items.due_between(Date.today.beginning_of_week, Date.today.end_of_week)
      elsif filter_by_due_this_month?
        items = items.due_between(Date.today.beginning_of_month, Date.today.end_of_month)
      end
    end

    items
  end

  def filter_by_no_due_date?
    due_date? && params[:due_date] == Issue::NoDueDate.name
  end

  def filter_by_overdue?
    due_date? && params[:due_date] == Issue::Overdue.name
  end

  def filter_by_due_this_week?
    due_date? && params[:due_date] == Issue::DueThisWeek.name
  end

  def filter_by_due_this_month?
    due_date? && params[:due_date] == Issue::DueThisMonth.name
  end

  def due_date?
    params[:due_date].present?
  end

  def user_can_see_all_confidential_issues?
    return @user_can_see_all_confidential_issues if defined?(@user_can_see_all_confidential_issues)

    return @user_can_see_all_confidential_issues = false if current_user.blank?
    return @user_can_see_all_confidential_issues = true if current_user.full_private_access?

    @user_can_see_all_confidential_issues =
      project? &&
      project &&
      project.team.max_member_access(current_user.id) >= CONFIDENTIAL_ACCESS_LEVEL
  end

  def user_cannot_see_confidential_issues?
    return false if user_can_see_all_confidential_issues?

    current_user.blank?
  end

  def by_assignee(items)
    if assignees.any?
      assignees.each do |assignee|
        items = items.assigned_to(assignee)
      end

      items
    elsif assignee && assignees.empty?
      items.assigned_to(assignee)
    elsif no_assignee?
      items.unassigned
    elsif assignee_id? || assignee_username? # assignee not found
      items.none
    else
      items
    end
  end

  def assignees
    return @assignees if defined?(@assignees)

    @assignees =
      if params[:assignee_ids]
        User.where(id: params[:assignee_ids])
      elsif params[:assignee_username]
        User.where(username: params[:assignee_username])
      else
        []
      end
  end

  def item_project_ids(items)
    items&.reorder(nil)&.select(:project_id)
  end
end
