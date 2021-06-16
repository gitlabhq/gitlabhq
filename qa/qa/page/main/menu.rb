# frozen_string_literal: true

module QA
  module Page
    module Main
      class Menu < Page::Base
        view 'app/views/layouts/header/_current_user_dropdown.html.haml' do
          element :sign_out_link
          element :edit_profile_link
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

        view 'app/assets/javascripts/nav/components/top_nav_app.vue' do
          element :navbar_dropdown
        end

        view 'app/assets/javascripts/nav/components/top_nav_dropdown_menu.vue' do
          element :menu_subview_container
        end

        view 'lib/gitlab/nav/top_nav_menu_item.rb' do
          element :menu_item_link
        end

        view 'app/helpers/nav/top_nav_helper.rb' do
          element :admin_area_link
          element :projects_dropdown
          element :groups_dropdown
          element :snippets_link
        end

        view 'app/views/layouts/_search.html.haml' do
          element :search_term_field
        end

        def go_to_groups
          within_groups_menu do
            click_element(:menu_item_link, title: 'Your groups')
          end
        end

        def go_to_create_group
          within_groups_menu do
            click_element(:menu_item_link, title: 'Create group')
          end
        end

        def go_to_projects
          within_projects_menu do
            click_element(:menu_item_link, title: 'Your projects')
          end
        end

        def go_to_create_project
          within_projects_menu do
            click_element(:menu_item_link, title: 'Create new project')
          end
        end

        def go_to_menu_dropdown_option(option_name)
          within_top_menu do
            click_element(:navbar_dropdown, title: 'Menu')
            click_element(option_name)
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

          return unless has_text?('Enter Admin Mode', wait: 1.0)

          Admin::NewSession.perform do |new_session|
            new_session.set_password(Runtime::User.admin_password)
            new_session.click_enter_admin_mode
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

        def click_edit_profile_link
          retry_until(reload: false) do
            within_user_menu do
              click_element(:edit_profile_link)
            end

            has_text?('User Settings')
          end
        end

        def click_user_profile_link
          within_user_menu do
            click_element(:user_profile_link)
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
          within_top_menu do
            click_element(:navbar_dropdown, title: 'Menu')
            has_element?(:admin_area_link, wait: wait)
          end
        end

        def has_no_admin_area_link?(wait: Capybara.default_max_wait_time)
          within_top_menu do
            click_element(:navbar_dropdown, title: 'Menu')
            has_no_element?(:admin_area_link, wait: wait)
          end
        end

        def click_stop_impersonation_link
          click_element(:stop_impersonation_link)
        end

        private

        def within_top_menu(&block)
          within_element(:navbar, &block)
        end

        def within_user_menu(&block)
          within_top_menu do
            click_element :user_avatar

            within_element(:user_menu, &block)
          end
        end

        def within_groups_menu(&block)
          go_to_menu_dropdown_option(:groups_dropdown)

          within_element(:menu_subview_container, &block)
        end

        def within_projects_menu(&block)
          go_to_menu_dropdown_option(:projects_dropdown)

          within_element(:menu_subview_container, &block)
        end

        def click_admin_area
          go_to_menu_dropdown_option(:admin_area_link)
        end
      end
    end
  end
end

QA::Page::Main::Menu.prepend_mod_with('Page::Main::Menu', namespace: QA)
