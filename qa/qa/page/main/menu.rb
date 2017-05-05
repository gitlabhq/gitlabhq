module QA
  module Page
    module Main
      class Menu < Page::Base
        def go_to_groups
          within_global_menu { click_link 'Groups' }
        end

        def go_to_projects
          within_global_menu { click_link 'Projects' }
        end

        def go_to_admin_area
          within_user_menu { click_link 'Admin area' }
        end

        def sign_out
          within_user_menu do
            find('.header-user-dropdown-toggle').click
            click_link('Sign out')
          end
        end

        def has_personal_area?
          page.has_selector?('.header-user-dropdown-toggle')
        end

        private

        def within_global_menu
          find('.global-dropdown-toggle').click

          page.within('.global-dropdown-menu') do
            yield
          end
        end

        def within_user_menu
          page.within('.navbar-nav') do
            yield
          end
        end
      end
    end
  end
end
