# frozen_string_literal: true

# SharedGroupsFinder
#
# Used to get the list of shared groups where the given group was invited
#
# Arguments:
#   group
#   current_user
#   params:
#     search: string
#
module Namespaces
  module Groups
    class SharedGroupsFinder
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

        groups = group.shared_groups.public_or_visible_to_user(current_user)
        groups = filter_shared_groups(groups)
        sort(groups).with_route
      end

      private

      def filter_shared_groups(groups)
        by_visibility(groups)
          .then { |filtered_groups| skip_groups(filtered_groups) }
          .then { |filtered_groups| by_search(filtered_groups) }
          .then { |filtered_groups| by_min_access_level(filtered_groups) }
      end
    end
  end
end

Namespaces::Groups::SharedGroupsFinder.prepend_mod
