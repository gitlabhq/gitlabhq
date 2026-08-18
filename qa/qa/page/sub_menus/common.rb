# frozen_string_literal: true

module QA
  module Page
    module SubMenus
      module Common
        SIDEBAR_RENDER_WAIT = 30

        def self.included(base)
          super

          base.class_eval do
            view 'app/assets/javascripts/super_sidebar/components/super_sidebar.vue' do
              element 'super-sidebar'
            end

            view 'app/assets/javascripts/super_sidebar/components/create_menu.vue' do
              element 'new-menu-toggle'
            end

            view 'app/assets/javascripts/super_sidebar/components/icon_only_toggle.vue' do
              element 'super-sidebar-collapse-button'
            end

            view 'app/assets/javascripts/super_sidebar/components/menu_section.vue' do
              element 'menu-section-button'
              element 'menu-section'
            end

            view 'app/assets/javascripts/super_sidebar/components/nav_item.vue' do
              element 'nav-item-link'
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
        # @param [String] sub_menu
        # @return [void]
        def open_submenu(parent_menu_name, sub_menu)
          wait_for_sidebar_render

          expand_sidebar_if_collapsed

          # prevent closing sub-menu if it was already open
          unless has_element?('menu-section', section_name: parent_menu_name, wait: 0)
            click_element('menu-section-button', section_name: parent_menu_name)
          end

          within_element('menu-section', section_name: parent_menu_name) do
            click_element('nav-item-link', submenu_item: sub_menu)
          end
        end

        # Waits for the sidebar's Vue app to mount
        #
        # The server-rendered placeholder already carries the `super-sidebar` class but not its
        # test id, so the test id appearing is what tells us the section buttons exist. Failing
        # here names the render race directly, rather than letting it resurface further down as
        # a missing section button.
        # @return [void]
        def wait_for_sidebar_render
          return if has_element?('super-sidebar', wait: SIDEBAR_RENDER_WAIT)

          raise Base::ElementNotFound,
            %(Super sidebar not found on #{current_url})
        end

        # Expands the sidebar if it's in icon-only (collapsed) mode
        # @return [void]
        def expand_sidebar_if_collapsed
          click_element('super-sidebar-collapse-button') if has_css?('.super-sidebar-is-icon-only', wait: 0)
        end
      end
    end
  end
end
