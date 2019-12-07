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
#     only_owned: boolean
#     only_shared: boolean
#     limit: integer
#   params:
#     sort: string
#     visibility_level: int
#     tags: string[]
#     personal: boolean
#     search: string
#     non_archived: boolean
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

  def limit(collection)
    limit = options[:limit]

    limit.present? ? collection.with_limit(limit) : collection
  end

  def init_collection
    projects = if current_user
                 collection_with_user
               else
                 collection_without_user
               end

    union(projects)
  end

  def collection_with_user
    if only_shared?
      [shared_projects.public_or_visible_to_user(current_user)]
    elsif only_owned?
      [owned_projects.public_or_visible_to_user(current_user)]
    else
      [
        owned_projects.public_or_visible_to_user(current_user),
        shared_projects.public_or_visible_to_user(current_user)
      ]
    end
  end

  def collection_without_user
    if only_shared?
      [shared_projects.public_only]
    elsif only_owned?
      [owned_projects.public_only]
    else
      [shared_projects.public_only, owned_projects.public_only]
    end
  end

  def union(items)
    if items.one?
      items.first
    else
      find_union(items, Project)
    end
  end

  def only_owned?
    options.fetch(:only_owned, false)
  end

  def only_shared?
    options.fetch(:only_shared, false)
  end

  # subgroups are supported only for owned projects not for shared
  def include_subgroups?
    options.fetch(:include_subgroups, false)
  end

  def owned_projects
    if include_subgroups?
      Project.for_group_and_its_subgroups(group)
    else
      group.projects
    end
  end

  def shared_projects
    group.shared_projects
  end
end

GroupProjectsFinder.prepend_if_ee('EE::GroupProjectsFinder')
