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
#
class IssuesFinder < IssuableFinder
  CONFIDENTIAL_ACCESS_LEVEL = Gitlab::Access::REPORTER

  def klass
    Issue
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
    with_confidentiality_access_check
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

  # Anonymous users can't see any confidential issues.
  #
  # Users without access to see _all_ confidential issues (as in
  # `user_can_see_all_confidential_issues?`) are more complicated, because they
  # can see confidential issues where:
  # 1. They are an assignee.
  # 2. They are an author.
  #
  # That's fine for most cases, but if we're just counting, we need to cache
  # effectively. If we cached this accurately, we'd have a cache key for every
  # authenticated user without sufficient access to the project. Instead, when
  # we are counting, we treat them as if they can't see any confidential issues.
  #
  # This does mean the counts may be wrong for those users, but avoids an
  # explosion in cache keys.
  def user_cannot_see_confidential_issues?(for_counting: false)
    return false if user_can_see_all_confidential_issues?

    current_user.blank? || for_counting || params[:for_counting]
  end

  def state_counter_cache_key_components
    extra_components = [
      user_can_see_all_confidential_issues?,
      user_cannot_see_confidential_issues?(for_counting: true)
    ]

    super + extra_components
  end

  def state_counter_cache_key_components_permutations
    # Ignore the last two, as we'll provide both options for them.
    components = super.first[0..-3]

    [
      components + [false, true],
      components + [true, false]
    ]
  end

  def by_assignee(items)
    if assignee
      items.assigned_to(assignee)
    elsif no_assignee?
      items.unassigned
    elsif assignee_id? || assignee_username? # assignee not found
      items.none
    else
      items
    end
  end

  def item_project_ids(items)
    items&.reorder(nil)&.select(:project_id)
  end
end
