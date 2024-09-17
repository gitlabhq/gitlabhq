# frozen_string_literal: true

# Projects::InvitedGroupsFinder
#
# Used to get the list of invited groups in the given project
# Arguments:
#   group
#   current_user
#   params:
#     relation: string - groups by relation (direct or inherited)
#     search: string
#     min_access_level: integer
#
module Namespaces
  module Projects
    class InvitedGroupsFinder
      include Namespaces::GroupsFilter
      include Gitlab::Allowable

      def initialize(project, current_user = nil, params = {})
        @project = project
        @current_user = current_user
        @params = params
      end

      def execute
        return Group.none unless can?(current_user, :read_project, project)

        groups = group_links(include_relations).public_or_visible_to_user(current_user)
        groups = apply_filters(groups)
        sort(groups).with_route
      end

      private

      attr_reader :project, :current_user, :params

      def include_relations
        Array(params[:relation]).map(&:to_sym)
      end

      def group_links(include_relations)
        case include_relations
        when [:direct]
          direct
        when [:inherited]
          inherited
        else
          Group.from_union(direct, inherited)
        end
      end

      def direct
        Group.id_in(project.project_group_links.select(:group_id))
      end

      def inherited
        Group.id_in(project.group_group_links.distinct_on_shared_with_group_id_with_group_access
                      .select(:shared_with_group_id))
      end
    end
  end
end

Namespaces::Projects::InvitedGroupsFinder.prepend_mod
