# frozen_string_literal: true

module QA
  module Page
    module Main
      class Menu < Page::Base
        view 'app/views/layouts/header/_current_user_dropdown.html.haml' do
          element :sign_out_link
          element :settings_link
        end

        view 'app/views/layouts/header/_default.html.haml' do
          element :navbar, required: true
          element :user_avatar, required: true
          element :user_menu, required: true
          element :stop_impersonation_link
          element :issues_shortcut_button, required: true
          element :merge_requests_shortcut_button, required: true
          element :todos_shortcut_button, required: true
        end

        view 'app/views/layouts/nav/_dashboard.html.haml' do
          element :admin_area_link
          element :projects_dropdown, required: true
          element :groups_dropdown, required: true
          element :more_dropdown
          element :snippets_link
          element :groups_link
          element :activity_link
          element :milestones_link
        end

        view 'app/views/layouts/nav/projects_dropdown/_show.html.haml' do
          element :projects_dropdown_sidebar
          element :your_projects_link
        end

        view 'app/views/layouts/_search.html.haml' do
          element :search_term_field
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

        def go_to_more_dropdown_option(option_name)
          within_top_menu do
            click_element :more_dropdown
            click_element option_name
          end
        end

        # To go to one of the popular pages using the provided shortcut buttons within top menu
        # @param [Symbol] the name of the element (e.g: `:issues_shortcut button`)
        # @example:
        #   Menu.perform do |menu|
        #     menu.go_to_page_by_shortcut(:issues_shortcut_button) #=> Go to Issues page using shortcut button
        #   end
        def go_to_page_by_shortcut(button)
          within_top_menu do
            click_element(button)
          end
        end

        def go_to_admin_area
          click_admin_area

          if has_text?('Enter Admin Mode', wait: 1.0)
            Admin::NewSession.perform do |new_session|
              new_session.set_password(Runtime::User.admin_password)
              new_session.click_enter_admin_mode
            end
          end
        end

        def signed_in?
          has_personal_area?(wait: 0)
        end

        def not_signed_in?
          has_no_personal_area?
        end

        def sign_out
          retry_until do
            wait_if_retry_later

            break true unless signed_in?

            within_user_menu do
              click_element :sign_out_link
            end

            has_no_element?(:user_avatar)
          end
        end

        def sign_out_if_signed_in
          sign_out if signed_in?
        end

        def click_settings_link
          retry_until(reload: false) do
            within_user_menu do
              click_link 'Settings'
            end

            has_text?('User Settings')
          end
        end

        def search_for(term)
          fill_element :search_term_field, "#{term}\n"
        end

        def has_personal_area?(wait: Capybara.default_max_wait_time)
          has_element?(:user_avatar, wait: wait)
        end

        def has_no_personal_area?(wait: Capybara.default_max_wait_time)
          has_no_element?(:user_avatar, wait: wait)
        end

        def has_admin_area_link?(wait: Capybara.default_max_wait_time)
          has_element?(:admin_area_link, wait: wait)
        end

        def has_no_admin_area_link?(wait: Capybara.default_max_wait_time)
          has_no_element?(:admin_area_link, wait: wait)
        end

        def click_stop_impersonation_link
          click_element(:stop_impersonation_link)
        end

        private

        def within_top_menu
          within_element(:navbar) do
            yield
          end
        end

        def within_user_menu
          within_top_menu do
            click_element :user_avatar

            within_element(:user_menu) do
              yield
            end
          end
        end

        def click_admin_area
          within_top_menu { click_element :admin_area_link }
        end
      end
    end
  end
end

QA::Page::Main::Menu.prepend_if_ee('QA::EE::Page::Main::Menu')
