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
#   params:
#     sort: string
#     visibility_level: int
#     tags: string[]
#     personal: boolean
#     search: string
#     non_archived: boolean
#
class GroupProjectsFinder < ProjectsFinder
  attr_reader :group, :options

  def initialize(group:, params: {}, options: {}, current_user: nil, project_ids_relation: nil)
    super(params: params, current_user: current_user, project_ids_relation: project_ids_relation)
    @group   = group
    @options = options
  end

  private

  def init_collection
    only_owned  = options.fetch(:only_owned, false)
    only_shared = options.fetch(:only_shared, false)

    projects = []

    if current_user
      if group.users.include?(current_user)
        projects << group.projects unless only_shared
        projects << group.shared_projects unless only_owned
      else
        unless only_shared
          projects << group.projects.visible_to_user(current_user)
          projects << group.projects.public_to_user(current_user)
        end

        unless only_owned
          projects << group.shared_projects.visible_to_user(current_user)
          projects << group.shared_projects.public_to_user(current_user)
        end
      end
    else
      projects << group.projects.public_only unless only_shared
      projects << group.shared_projects.public_only unless only_owned
    end

    projects
  end

  def union(items)
    find_union(items, Project)
  end
end
