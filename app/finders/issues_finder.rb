# frozen_string_literal: true

# Finders::Issues class
#
# Used to filter Issues collections by set of params
#
# Arguments:
#   current_user - which user use
#   params:
#     scope: 'created_by_me' or 'assigned_to_me' or 'all'
#     state: 'opened' or 'closed' or 'all'
#     group_id: integer
#     project_id: integer
#     milestone_title: string
#     assignee_id: integer
#     search: string
#     in: 'title', 'description', or a string joining them with comma
#     label_name: string
#     sort: string
#     my_reaction_emoji: string
#     public_only: boolean
#     due_date: date or '0', '', 'overdue', 'week', or 'month'
#     created_after: datetime
#     created_before: datetime
#     updated_after: datetime
#     updated_before: datetime
#     confidential: boolean
#     issue_types: array of strings (one of Issue.issue_types)
#
class IssuesFinder < IssuableFinder
  CONFIDENTIAL_ACCESS_LEVEL = Gitlab::Access::REPORTER

  def self.scalar_params
    @scalar_params ||= super + [:due_date]
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def klass
    Issue.includes(:author)
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def params_class
    self.class.const_get(:Params, false)
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def with_confidentiality_access_check
    return Issue.all if params.user_can_see_all_confidential_issues?

    # If already filtering by assignee we can skip confidentiality since a user
    # can always see confidential issues assigned to them. This is just an
    # optimization since a very common usecase of this Finder is to load the
    # count of issues assigned to the user for the header bar.
    return Issue.all if current_user && assignee_filter.includes_user?(current_user)

    return Issue.where('issues.confidential IS NOT TRUE') if params.user_cannot_see_confidential_issues?

    Issue.where('
      issues.confidential IS NOT TRUE
      OR (issues.confidential = TRUE
        AND (issues.author_id = :user_id
          OR EXISTS (SELECT TRUE FROM issue_assignees WHERE user_id = :user_id AND issue_id = issues.id)
          OR EXISTS (:authorizations)))',
      user_id: current_user.id,
      authorizations: current_user.authorizations_for_projects(min_access_level: CONFIDENTIAL_ACCESS_LEVEL, related_project_column: "issues.project_id"))
  end
  # rubocop: enable CodeReuse/ActiveRecord

  private

  def init_collection
    if params.public_only?
      Issue.public_only
    else
      with_confidentiality_access_check
    end
  end

  def filter_items(items)
    issues = super
    issues = by_due_date(issues)
    issues = by_confidential(issues)
    by_issue_types(issues)
  end

  def by_confidential(items)
    return items if params[:confidential].nil?

    params[:confidential] ? items.confidential_only : items.public_only
  end

  def by_due_date(items)
    return items unless params.due_date?

    if params.filter_by_no_due_date?
      items.without_due_date
    elsif params.filter_by_overdue?
      items.due_before(Date.today)
    elsif params.filter_by_due_this_week?
      items.due_between(Date.today.beginning_of_week, Date.today.end_of_week)
    elsif params.filter_by_due_this_month?
      items.due_between(Date.today.beginning_of_month, Date.today.end_of_month)
    elsif params.filter_by_due_next_month_and_previous_two_weeks?
      items.due_between(Date.today - 2.weeks, (Date.today + 1.month).end_of_month)
    else
      items.none
    end
  end

  def by_issue_types(items)
    issue_type_params = Array(params[:issue_types]).map(&:to_s)
    return items if issue_type_params.blank?
    return Issue.none unless (Issue.issue_types.keys & issue_type_params).sort == issue_type_params.sort

    items.with_issue_type(params[:issue_types])
  end
end

IssuesFinder.prepend_mod_with('IssuesFinder')
