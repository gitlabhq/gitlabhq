# frozen_string_literal: true

# Used to filter ancestor and shared project's Groups by a set of params
#
# Arguments:
#   project
#   current_user - which user is requesting groups
#   params:
#     with_shared: boolean (optional)
#     shared_visible_only: boolean (optional)
#     shared_min_access_level: integer (optional)
#     skip_groups: array of integers (optional)
#
module Projects
  class GroupsFinder < UnionFinder
    def initialize(project:, current_user: nil, params: {})
      @project = project
      @current_user = current_user
      @params = params
    end

    def execute
      return Group.none unless authorized?

      items = all_groups.map do |item|
        item = exclude_group_ids(item)
        item
      end

      find_union(items, Group).with_route.order_id_desc
    end

    private

    attr_reader :project, :current_user, :params

    def authorized?
      Ability.allowed?(current_user, :read_project, project)
    end

    def all_groups
      groups = []
      groups += [project.group.self_and_ancestors] if project.group
      groups += with_shared_groups if params[:with_shared]

      return [Group.none] if groups.compact.empty?

      groups
    end

    def with_shared_groups
      shared_groups = project.invited_groups
      shared_groups = apply_min_access_level(shared_groups)

      if params[:shared_visible_only]
        [
          shared_groups.public_to_user(current_user),
          shared_groups.for_authorized_group_members(current_user&.id)
        ]
      else
        [shared_groups]
      end
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def apply_min_access_level(groups)
      return groups unless params[:shared_min_access_level]

      groups.where('project_group_links.group_access >= ?', params[:shared_min_access_level])
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def exclude_group_ids(groups)
      return groups unless params[:skip_groups]

      groups.id_not_in(params[:skip_groups])
    end
  end
end
