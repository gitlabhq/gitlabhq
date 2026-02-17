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
#     milestone_title: string (cannot be simultaneously used with milestone_wildcard_id)
#     milestone_wildcard_id: 'none', 'any', 'upcoming', 'started' (cannot be simultaneously used with milestone_title)
#     assignee_id: integer
#     closed_by_id: integer
#     search: string
#     in: 'title', 'description', or a string joining them with comma
#     label_name: string
#     sort: string
#     my_reaction_emoji: string
#     due_date: date or '0', '', 'overdue', 'week', or 'month'
#     due_after: datetime
#     due_before: datetime
#     created_after: datetime
#     created_before: datetime
#     updated_after: datetime
#     updated_before: datetime
#     confidential: boolean
#     issue_types: array of strings (one of ::WorkItems::TypesFramework::Provider.new.unfiltered_base_types)
#
class IssuesFinder < IssuableFinder
  extend ::Gitlab::Utils::Override
  include Gitlab::Utils::StrongMemoize

  # Both short (created_desc) and long (created_at_desc) formats are needed because
  # the GraphQL API uses short format while the REST API uses long format.
  ROOT_TRAVERSAL_IDS_SORTING_OPTIONS = %w[
    updated_asc updated_desc created_asc created_desc
    updated_at_asc updated_at_desc created_at_asc created_at_desc
  ].freeze

  def self.scalar_params
    @scalar_params ||= super + [:due_date]
  end

  def klass
    Issue
  end

  def params_class
    self.class.const_get(:Params, false)
  end

  def use_cte_for_search?
    # It's more performant to directly filter on the `issues` table without a CTE
    # https://gitlab.com/gitlab-org/gitlab/-/merge_requests/214847
    use_namespace_traversal_ids_filtering? ? false : super
  end

  def use_full_text_search?
    # Full-text search with namespace_traversal_ids filtering is not performant
    # because the issue_search_data table is partitioned by project_id,
    # and partition pruning cannot occur when filtering by namespace hierarchy
    return false if use_namespace_traversal_ids_filtering?

    super
  end

  private

  override :use_minimum_char_limit?
  def use_minimum_char_limit?
    # When traversal_ids is enabled, we don't want to use CTE search (see above).
    # But we also don't want to set a character limit, otherwise we don't perform a exact search.
    # e.g. `My Title 1` would be split into `['My', 'Title', '1']`
    return false if use_namespace_traversal_ids_filtering?

    super
  end

  override :by_parent
  def by_parent(items)
    return super unless use_namespace_traversal_ids_filtering?

    items_within_hierarchy = items
      .within_namespace_hierarchy(ancestor_group)
      .join_project
      .merge(Project.with_issues_enabled)

    items_within_hierarchy = filter_by_projects(items_within_hierarchy)

    ensure_state_filter_for_index(items_within_hierarchy)
  end

  def filter_by_projects(items)
    return items unless params[:projects].present?

    items.in_projects(params[:projects])
  end

  # If the state filter is not present in the params we manually add it to filter all available states
  # This is needed because state_id is required for index utilization
  # See: https://gitlab.com/gitlab-org/gitlab/-/issues/562319
  def ensure_state_filter_for_index(items)
    return items if state_filter_passed?

    items.with_state(*klass.available_state_names)
  end

  def use_namespace_traversal_ids_filtering?
    return false unless params.group?
    return false unless include_subgroups_or_descendants?
    return false unless ::Feature.enabled?(:use_namespace_traversal_ids_for_work_items_finder, current_user)
    return false unless user_can_access_all_subgroup_items?

    # For sub-groups it's performant enough to use the traversal_ids and sort in memory.
    return true unless params.group.root?

    # For root groups with include_subgroups, we don't have an index on all columns that we support sorting for.
    # For all columns we don't have an index for, we need to fallback to the old query.
    sorting_covered_by_index?
  end
  strong_memoize_attr :use_namespace_traversal_ids_filtering?

  def include_subgroups_or_descendants?
    params[:include_subgroups].present?
  end

  def user_can_access_all_subgroup_items?
    return false unless ancestor_group

    Ability.allowed?(current_user, :read_all_resources) || ancestor_group.member?(current_user)
  end

  def ancestor_group
    params.group
  end
  strong_memoize_attr :ancestor_group

  def state_filter_passed?
    params[:state].present? && params[:state].to_s != 'all'
  end

  def sorting_covered_by_index?
    return true if params[:sort].blank?

    params[:sort].to_s.in?(ROOT_TRAVERSAL_IDS_SORTING_OPTIONS)
  end

  def filter_items(items)
    issues = by_service_desk(items) # Call before super because we remove params
    issues = super(issues)
    issues = by_due_date(issues)
    issues = by_due_after_or_before(issues)
    issues = by_confidential(issues)
    by_issue_types(issues)
  end

  # Negates all params found in `negatable_params`
  def filter_negated_items(items)
    issues = super
    by_negated_issue_types(issues)
  end

  override :filter_by_full_text_search
  def filter_by_full_text_search(items)
    # This project condition is used as a hint to PG about the partitions that need searching
    # because the search data is partitioned by project.
    # In certain cases, like the recent items search, the query plan is much better without this condition.
    return super if params[:skip_full_text_search_project_condition].present?

    super.with_projects_matching_search_data
  end

  def by_confidential(items)
    Issues::ConfidentialityFilter.new(
      current_user: current_user,
      params: original_params,
      parent: params.parent,
      assignee_filter: assignee_filter
    ).filter(items)
  end

  def by_due_after_or_before(items)
    items = items.due_after(params[:due_after]) if params[:due_after].present?
    items = items.due_before(params[:due_before]) if params[:due_before].present?

    items
  end

  def by_due_date(items)
    return items unless params.due_date?

    if params.filter_by_no_due_date?
      items.without_due_date
    elsif params.filter_by_any_due_date?
      items.with_due_date
    elsif params.filter_by_overdue?
      items.due_before(Date.today)
    elsif params.filter_by_due_today?
      items.due_today
    elsif params.filter_by_due_tomorrow?
      items.due_tomorrow
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
    types_filter.filter(items)
  end

  def types_filter
    Issues::IssueTypesFilter.new(
      params: original_params,
      parent: params.parent
    )
  end
  strong_memoize_attr :types_filter

  def by_service_desk(items)
    return items unless params[:author_username] == "support-bot"

    # Delete param so we don't additionally filter by author username
    params.delete(:author_username)
    # Also delete from here because we pass original_params to
    # Issuables::AuthorFilter in IssuableFinder
    original_params.delete(:author_username)

    items.service_desk
  end

  def by_negated_issue_types(items)
    provider = ::WorkItems::TypesFramework::Provider.new(params.parent)
    issue_type_params = Array(not_params[:issue_types]).map(&:to_s) & provider.unfiltered_base_types
    return items if issue_type_params.blank?

    items.without_issue_type(issue_type_params)
  end
end

IssuesFinder.prepend_mod_with('IssuesFinder')
