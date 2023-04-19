# frozen_string_literal: true

module QA
  module Page
    module SubMenus
      module Common
        prepend Mobile::Page::SubMenus::Common if QA::Runtime::Env.mobile_layout?

        def hover_element(element)
          within_sidebar do
            find_element(element).hover
            yield
          end
        end

        def within_sidebar(&block)
          wait_for_requests

          within_element(sidebar_element, &block)
        end

        def within_submenu(element = nil, &block)
          if element
            within_element(element, &block)
          else
            within_submenu_without_element(&block)
          end
        end

        private

        # Opens the new item menu and yields to the block
        #
        # @return [void]
        def within_new_item_menu
          click_element(:new_menu_toggle)

          yield
        end

        # Implementation for super-sidebar, will replace within_submenu
        #
        # @param [String] parent_menu_name
        # @param [String] parent_section_id
        # @param [String] sub_menu
        # @return [void]
        def open_submenu(parent_menu_name, sub_menu)
          click_element(:nav_item_link, menu_item: parent_menu_name)

          within_element(:menu_section, section: parent_menu_name) do
            click_element(:nav_item_link, submenu_item: sub_menu)
          end
        end

        def within_submenu_without_element(&block)
          has_css?('.fly-out-list') ? within('.fly-out-list', &block) : yield
        end

        def sidebar_element
          raise NotImplementedError
        end
      end
    end
  end
end
