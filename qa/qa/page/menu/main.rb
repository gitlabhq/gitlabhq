module QA
  module Page
    module Menu
      class Main < Page::Base
        view 'app/views/layouts/header/_current_user_dropdown.html.haml' do
          element :btn_signout
          element :btn_settings
        end

        view 'app/views/layouts/header/_default.html.haml' do
          element :navbar
          element :user_avatar
          element :drp_user
        end

        view 'app/views/layouts/nav/_dashboard.html.haml' do
          element :lnk_adminarea
          element :drp_projects
          element :drp_groups
        end

        view 'app/views/layouts/nav/projects_dropdown/_show.html.haml' do
          element :drp_projects_sidebar
          element :drp_projects_sidebar_lnk_yourprojects
        end

        view 'app/views/layouts/nav/groups_dropdown/_show.html.haml' do
          element :drp_groups_sidebar
          element :drp_groups_sidebar_lnk_yourgroups
        end

        def go_to_groups
          within_top_menu do
            click_element :drp_groups
          end

          page.within_element(:drp_groups_sidebar) do
            click_element :drp_groups_sidebar_lnk_yourgroups
          end
        end

        def go_to_projects
          within_top_menu do
            click_element :drp_projects
          end

          page.within_element(:drp_projects_sidebar) do
            click_element :drp_projects_sidebar_lnk_yourprojects
          end
        end

        def go_to_admin_area
          within_top_menu { click_element :lnk_adminarea }
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

        def has_personal_area?(wait: Capybara.default_max_wait_time)
          # No need to wait, either we're logged-in, or not.
          using_wait_time(wait) { page.has_selector?('.qa-user-avatar') }
        end

        private

        def within_top_menu
          page.within_element(:navbar) do
            yield
          end
        end

        def within_user_menu
          within_top_menu do
            click_element :user_avatar

            page.within_element(:drp_user) do
              yield
            end
          end
        end
      end
    end
  end
end
