# frozen_string_literal: true

# GroupProjectsFinder
#
# Used to filter Projects  by set of params
#
# Arguments:
#   current_user - which user use
#   project_ids_relation: int[] - project ids to use
#   group
#   options:
#     exclude_shared: boolean
#       When true, only projects within the group are included in the result.
#     only_shared: boolean
#       When true, only projects arising from group-project shares are included in the result.
#     limit: integer
#     include_subgroups: boolean
#     include_ancestor_groups: boolean
#   params:
#     sort: string
#     visibility_level: int
#     tags: string[]
#     personal: boolean
#     search: string
#     non_archived: boolean
#     with_issues_enabled: boolean
#     with_merge_requests_enabled: boolean
#     min_access_level: int
#     owned: boolean
#
class GroupProjectsFinder < ProjectsFinder
  DEFAULT_PROJECTS_LIMIT = 100

  attr_reader :group, :options

  def initialize(group:, params: {}, options: {}, current_user: nil, project_ids_relation: nil)
    super(
      params: params,
      current_user: current_user,
      project_ids_relation: project_ids_relation
    )
    @group = group
    @options = options
  end

  def execute
    collection = super
    limit(collection)
  end

  private

  def filter_projects(collection)
    projects = super
    by_feature_availability(projects)
  end

  def limit(collection)
    limit = options[:limit]

    limit.present? ? collection.with_limit(limit) : collection
  end

  def init_collection
    projects =
      if only_shared?
        [shared_projects]
      elsif exclude_shared?
        [projects_within_group]
      else
        [projects_within_group, shared_projects]
      end

    projects.map! do |project_relation|
      filter_by_visibility(project_relation)
    end

    union(projects)
  end

  def by_feature_availability(projects)
    projects = projects.with_issues_available_for_user(current_user) if params[:with_issues_enabled].present?
    if params[:with_merge_requests_enabled].present?
      projects = projects.with_merge_requests_available_for_user(current_user)
    end

    projects
  end

  def filter_by_visibility(relation)
    if current_user
      if owned_projects?
        relation.visible_to_user_and_access_level(current_user, Gitlab::Access::OWNER)
      elsif min_access_level?
        relation.visible_to_user_and_access_level(current_user, params[:min_access_level])
      else
        relation.public_or_visible_to_user(current_user)
      end
    else
      relation.public_only
    end
  end

  def union(items)
    if items.one?
      items.first
    else
      find_union(items, Project)
    end
  end

  def exclude_shared?
    options.fetch(:exclude_shared, false)
  end

  def owned_projects?
    params.fetch(:owned, false)
  end

  def only_shared?
    options.fetch(:only_shared, false)
  end

  # subgroups are supported only for owned projects not for shared
  def include_subgroups?
    options.fetch(:include_subgroups, false)
  end

  # ancestor groups are supported only for owned projects not for shared
  def include_ancestor_groups?
    options.fetch(:include_ancestor_groups, false)
  end

  def projects_within_group
    return group.projects unless include_subgroups? || include_ancestor_groups?

    union_relations = []
    union_relations << Project.for_group_and_its_subgroups(group) if include_subgroups?
    union_relations << Project.for_group_and_its_ancestor_groups(group) if include_ancestor_groups?

    Project.from_union(union_relations)
  end

  def shared_projects
    group.shared_projects
  end
end

GroupProjectsFinder.prepend_mod_with('GroupProjectsFinder')
