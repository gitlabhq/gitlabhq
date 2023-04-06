# frozen_string_literal: true

module QA
  module Page
    module SubMenus
      module Common
        # We need to check remote_mobile_device_name instead of mobile_layout? here
        # since tablets have the regular top navigation bar but still close the left nav
        prepend Mobile::Page::SubMenus::Common if QA::Runtime::Env.remote_mobile_device_name

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

        # Implementation for super-sidebar, will replace within_submenu
        #
        # @param [String] parent_menu_name
        # @param [String] parent_section_id
        # @param [String] sub_menu
        # @return [void]
        def open_submenu(parent_menu_name, parent_section_id, sub_menu)
          click_element(:sidebar_menu_link, menu_item: parent_menu_name)

          # TODO: it's not possible to add qa-selectors to sub-menu container
          within(parent_section_id) do
            click_element(:sidebar_menu_link, menu_item: sub_menu)
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
