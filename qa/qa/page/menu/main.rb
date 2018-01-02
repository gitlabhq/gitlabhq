module QA
  module Page
    module Menu
      class Main < Page::Base
        def go_to_groups
          within_top_menu { click_link 'Groups' }
        end

        def go_to_projects
          within_top_menu do
            click_link 'Projects'
            click_link 'Your projects'
          end
        end

        def go_to_admin_area
          within_top_menu { find('.admin-icon').click }
        end

        def sign_out
          within_user_menu do
            click_link('Sign out')
          end
        end

        def has_personal_area?
          page.has_selector?('.header-user-dropdown-toggle')
        end

        private

        def within_top_menu
          page.within('.navbar') do
            yield
          end
        end

        def within_user_menu
          within_top_menu do
            find('.header-user-dropdown-toggle').click

            page.within('.dropdown-menu-nav') do
              yield
            end
          end
        end
      end
    end
  end
end
