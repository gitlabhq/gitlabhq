# frozen_string_literal: true

# Used to filter ancestor and shared project's Groups by a set of params
#
# Arguments:
#   project
#   current_user - which user is requesting groups
#   params:
#     with_shared: boolean (optional)
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

    # rubocop: disable CodeReuse/ActiveRecord
    def all_groups
      groups = []
      groups << project.group.self_and_ancestors if project.group

      if params[:with_shared]
        shared_groups = project.invited_groups

        if params[:shared_min_access_level]
          shared_groups = shared_groups.where(
            'project_group_links.group_access >= ?', params[:shared_min_access_level]
          )
        end

        groups << shared_groups
      end

      groups << Group.none if groups.compact.empty?
      groups
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def exclude_group_ids(groups)
      return groups unless params[:skip_groups]

      groups.id_not_in(params[:skip_groups])
    end
  end
end
