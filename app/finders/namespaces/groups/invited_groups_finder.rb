# frozen_string_literal: true

# InvitedGroupsFinder
#
# Used to get the list of invited groups in the given group
# Arguments:
#   group
#   current_user
#   params:
#     relations: string
#     search: string
#     min_access_level: integer
#
module Namespaces
  module Groups
    class InvitedGroupsFinder
      include ::Groups::GroupMembersHelper
      include Namespaces::GroupsFilter
      include Gitlab::Allowable

      attr_reader :group, :current_user, :params

      def initialize(group, current_user = nil, params = {})
        @group = group
        @current_user = current_user
        @params = params
      end

      def execute
        return Group.none unless can?(current_user, :read_group, group)

        group_links = group_group_links(group, include_relations)
        groups = Group.id_in(group_links.select(:shared_with_group_id)).public_or_visible_to_user(current_user)
        groups = filter_invited_groups(groups)
        sort(groups).with_route
      end

      private

      def filter_invited_groups(groups)
        by_search(groups)
        .then { |filtered_groups| by_min_access_level(filtered_groups) }
      end

      def include_relations
        [params[:relation].try(:to_sym)]
      end
    end
  end
end

Namespaces::Groups::InvitedGroupsFinder.prepend_mod
