# frozen_string_literal: true

module QA
  module Page
    module SubMenus
      module Common
        def self.included(base)
          super

          base.class_eval do
            view 'app/assets/javascripts/super_sidebar/components/super_sidebar.vue' do
              element :navbar
            end
          end
        end

        private

        # Opens the new item menu and yields to the block
        #
        # @return [void]
        def within_new_item_menu
          click_element('new-menu-toggle')

          yield
        end

        # Open sidebar navigation submenu
        #
        # @param [String] parent_menu_name
        # @param [String] parent_section_id
        # @param [String] sub_menu
        # @return [void]
        def open_submenu(parent_menu_name, sub_menu)
          # prevent closing sub-menu if it was already open
          unless has_element?(:menu_section, section_name: parent_menu_name, wait: 0)
            click_element(:menu_section_button, section_name: parent_menu_name)
          end

          within_element(:menu_section, section_name: parent_menu_name) do
            click_element('nav-item-link', submenu_item: sub_menu)
          end
        end
      end
    end
  end
end
