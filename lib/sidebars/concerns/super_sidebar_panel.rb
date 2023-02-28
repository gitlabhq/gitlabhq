# frozen_string_literal: true

module Sidebars
  module Concerns
    # Contains helper methods aid conversion of a "normal" panel
    # into a Super Sidebar Panel
    module SuperSidebarPanel
      # Picks an element from the given list and adds it to the current menus
      # Used for menus which behave the same in the old nav and Supersidebar
      def pick_from_old_menus(old_menus, element)
        add_menu(remove_element(old_menus, element))
      end

      def transform_old_menus(current_menus, *old_menus)
        old_menus.each do |menu|
          next unless menu.render?

          menu.renderable_items.each { |item| add_menu_item_to_super_sidebar_parent(current_menus, item) }

          menu_item_args = menu.serialize_as_menu_item_args

          next if menu_item_args.nil?

          add_menu_item_to_super_sidebar_parent(
            current_menus, ::Sidebars::MenuItem.new(**menu_item_args)
          )
        end
      end

      private

      # Finds a menu_items super sidebar parent and adds the item to that menu
      # Handles:
      #   - menu_item.super_sidebar_before, adding before a certain item
      #   - parent == nil, or parent not being part of the panel:
      #       we assume that the menu item hasn't been categorized yet
      #   - parent == ::Sidebars::NilMenuItem, the item explicitly is supposed to be removed
      def add_menu_item_to_super_sidebar_parent(menus, menu_item)
        parent = menu_item.super_sidebar_parent || ::Sidebars::UncategorizedMenu
        return if parent == ::Sidebars::NilMenuItem

        idx = index_of(menus, parent) || index_of(menus, ::Sidebars::UncategorizedMenu)
        return unless idx

        if menu_item.super_sidebar_before
          menus[idx].insert_item_before(menu_item.super_sidebar_before, menu_item)
        else
          menus[idx].add_item(menu_item)
        end
      end
    end
  end
end
