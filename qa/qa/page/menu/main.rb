module QA
  module Page
    module Menu
      class Main < Page::Base
        view 'app/views/layouts/header/_default.html.haml' do
          element :navbar
          element :user_avatar
          element :user_menu, '.dropdown-menu-nav'
          element :user_sign_out_link, 'link_to "Sign out"'
          element :settings_link, 'link_to "Settings"'
        end

        view 'app/views/layouts/nav/_dashboard.html.haml' do
          element :admin_area_link
          element :projects_dropdown
          element :groups_link
        end

        view 'app/views/layouts/nav/projects_dropdown/_show.html.haml' do
          element :projects_dropdown_sidebar
          element :your_projects_link
        end

        def go_to_groups
          within_top_menu { click_element :groups_link }
        end

        def go_to_projects
          within_top_menu do
            click_element :projects_dropdown
          end

          page.within('.qa-projects-dropdown-sidebar') do
            click_element :your_projects_link
          end
        end

        def go_to_admin_area
          within_top_menu { click_element :admin_area_link }
        end

        def sign_out
          within_user_menu do
            click_link 'Sign out'
          end
        end

        def go_to_profile_settings
          within_user_menu do
            click_link 'Settings'
          end
        end

        def has_personal_area?
          page.has_selector?('.qa-user-avatar')
        end

        private

        def within_top_menu
          page.within('.qa-navbar') do
            yield
          end
        end

        def within_user_menu
          within_top_menu do
            click_element :user_avatar

            page.within('.dropdown-menu-nav') do
              yield
            end
          end
        end
      end
    end
  end
end
