# frozen_string_literal: true

module QA
  module Page
    module Main
      class Menu < Page::Base
        view 'app/views/layouts/header/_current_user_dropdown.html.haml' do
          element :sign_out_link
          element :settings_link, 'link_to s_("CurrentUser|Settings")' # rubocop:disable QA/ElementWithPattern
        end

        view 'app/views/layouts/header/_default.html.haml' do
          element :navbar, required: true
          element :user_avatar, required: true
          element :user_menu, '.dropdown-menu' # rubocop:disable QA/ElementWithPattern
        end

        view 'app/views/layouts/nav/_dashboard.html.haml' do
          element :admin_area_link
          element :projects_dropdown, required: true
          element :groups_dropdown, required: true
          element :snippets_link
        end

        view 'app/views/layouts/nav/projects_dropdown/_show.html.haml' do
          element :projects_dropdown_sidebar
          element :your_projects_link
        end

        def go_to_groups
          within_top_menu do
            click_element :groups_dropdown
          end

          page.within('.qa-groups-dropdown-sidebar') do
            click_element :your_groups_link
          end
        end

        def go_to_projects
          within_top_menu do
            click_element :projects_dropdown
          end

          page.within('.qa-projects-dropdown-sidebar') do
            click_element :your_projects_link
          end
        end

        def click_admin_area
          within_top_menu { click_element :admin_area_link }
        end

        def sign_out
          within_user_menu do
            click_element :sign_out_link
          end
        end

        def click_settings_link
          retry_until(reload: false) do
            within_user_menu do
              click_link 'Settings'
            end

            has_text?('User Settings')
          end
        end

        def click_snippets_link
          click_element :snippets_link
        end

        def has_personal_area?(wait: Capybara.default_max_wait_time)
          has_element?(:user_avatar, wait: wait)
        end

        def has_admin_area_link?(wait: Capybara.default_max_wait_time)
          has_element?(:admin_area_link, wait: wait)
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

            page.within('.dropdown-menu') do
              yield
            end
          end
        end
      end
    end
  end
end
