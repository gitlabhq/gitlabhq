# frozen_string_literal: true

module QA
  module Page
<<<<<<< HEAD:qa/qa/page/menu/admin.rb
    module Menu
      class Admin < Page::Base
        prepend EE::Page::Menu::Admin

=======
    module Admin
      class Menu < Page::Base
>>>>>>> 12a11229dd440da1880858cbeb93fa33094474f3:qa/qa/page/admin/menu.rb
        view 'app/views/layouts/nav/sidebar/_admin.html.haml' do
          element :admin_sidebar
          element :admin_sidebar_submenu
          element :admin_settings_item
          element :admin_settings_repository_item
        end

        def go_to_repository_settings
          hover_settings do
            within_submenu do
              click_element :admin_settings_repository_item
            end
          end
        end

        private

        def hover_settings
          within_sidebar do
            scroll_to_element(:admin_settings_item)
            find_element(:admin_settings_item).hover

            yield
          end
        end

        def within_sidebar
          within_element(:admin_sidebar) do
            yield
          end
        end

        def within_submenu
          within_element(:admin_sidebar_submenu) do
            yield
          end
        end
      end
    end
  end
end
