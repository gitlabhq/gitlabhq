# frozen_string_literal: true

# This module has the necessary methods to render
# work items hierarchy menu
module Sidebars
  module Concerns
    module WorkItemHierarchy
      def hierarchy_menu_item(container, url, path)
        unless show_hierarachy_menu_item?(container)
          return ::Sidebars::NilMenuItem.new(item_id: :hierarchy)
        end

        ::Sidebars::MenuItem.new(
          title: _('Planning hierarchy'),
          link: url,
          active_routes: { path: path },
          item_id: :hierarchy
        )
      end

      def show_hierarachy_menu_item?(container)
        can?(context.current_user, :read_planning_hierarchy, container)
      end
    end
  end
end
