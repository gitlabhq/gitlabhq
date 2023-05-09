# frozen_string_literal: true

module QA
  module Page
    module Main
      class Menu < Page::Base
        # We need to check phone_layout? instead of mobile_layout? here
        # since tablets have the regular top navigation bar
        prepend Mobile::Page::Main::Menu if Runtime::Env.phone_layout?

        if Runtime::Env.super_sidebar_enabled?
          prepend SubMenus::CreateNewMenu
          include SubMenus::SuperSidebar::ContextSwitcher
        end

        if QA::Runtime::Env.super_sidebar_enabled?
          # Define alternative navbar (super sidebar) which does not yet implement all the same elements
          view 'app/assets/javascripts/super_sidebar/components/super_sidebar.vue' do
            element :navbar, required: true # TODO: rename to sidebar once it's default implementation
            element :user_menu, required: !Runtime::Env.phone_layout?
            element :user_avatar_content, required: !Runtime::Env.phone_layout?
          end

          view 'app/assets/javascripts/super_sidebar/components/user_menu.vue' do
            element :sign_out_link
            element :edit_profile_link
          end

          view 'app/assets/javascripts/super_sidebar/components/user_name_group.vue' do
            element :user_profile_link
          end

          view 'app/assets/javascripts/super_sidebar/components/user_bar.vue' do
            element :global_search_button
          end

          view 'app/assets/javascripts/super_sidebar/components/global_search/components/global_search.vue' do
            element :global_search_input
          end
        else
          view 'app/views/layouts/header/_default.html.haml' do
            element :navbar, required: true
            element :canary_badge_link
            element :user_avatar_content, required: !Runtime::Env.phone_layout?
            element :user_menu, required: !Runtime::Env.phone_layout?
            element :stop_impersonation_link
            element :issues_shortcut_button, required: !Runtime::Env.phone_layout?
            element :merge_requests_shortcut_button, required: !Runtime::Env.phone_layout?
            element :todos_shortcut_button, required: !Runtime::Env.phone_layout?
          end

          view 'app/views/layouts/header/_current_user_dropdown.html.haml' do
            element :sign_out_link
            element :edit_profile_link
            element :user_profile_link
          end
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
          element :menu_item_link
        end

        view 'app/views/layouts/_header_search.html.haml' do
          element :search_box
        end

        view 'app/assets/javascripts/header_search/components/app.vue' do
          element :global_search_input
        end

        view 'app/views/layouts/header/_new_dropdown.html.haml' do
          element :new_menu_toggle
        end

        view 'app/helpers/nav/new_dropdown_helper.rb' do
          element :global_new_group_link
          element :global_new_project_link
          element :global_new_snippet_link
        end

        view 'app/assets/javascripts/nav/components/new_nav_toggle.vue' do
          element :new_navigation_toggle
        end

        def go_to_projects
          return click_element(:nav_item_link, submenu_item: 'Projects') if Runtime::Env.super_sidebar_enabled?

          click_element(:sidebar_menu_link, menu_item: 'Projects')
        end

        def go_to_groups
          # This needs to be fixed in the tests themselves. Fullfillment tests try to go to groups view from the
          # group. Instead of having a global hack, explicit test should navigate to correct view first.
          # see: https://gitlab.com/gitlab-org/gitlab/-/issues/403589#note_1383040061
          if Runtime::Env.super_sidebar_enabled?
            go_to_your_work unless has_element?(:nav_item_link, submenu_item: 'Groups', wait: 0)
            click_element(:nav_item_link, submenu_item: 'Groups')
          elsif has_element?(:sidebar_menu_link, menu_item: 'Groups')
            # Use new functionality to visit Groups where possible
            click_element(:sidebar_menu_link, menu_item: 'Groups')
          else
            # Otherwise fallback to previous functionality
            # See https://gitlab.com/gitlab-org/gitlab/-/issues/403589
            # and related issues
            within_groups_menu do
              click_element(:menu_item_link, title: 'View all groups')
            end
          end
        end

        def go_to_snippets
          return click_element(:nav_item_link, submenu_item: 'Snippets') if Runtime::Env.super_sidebar_enabled?

          click_element(:sidebar_menu_link, menu_item: 'Snippets')
        end

        def go_to_create_project
          click_element(:new_menu_toggle)
          click_element(:global_new_project_link)
        end

        def go_to_create_group
          click_element(:new_menu_toggle)
          click_element(:global_new_group_link)
        end

        def go_to_create_snippet
          click_element(:new_menu_toggle)
          click_element(:global_new_snippet_link)
        end

        def go_to_menu_dropdown_option(option_name)
          return click_element(option_name) if QA::Runtime::Env.super_sidebar_enabled?

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
          Runtime::Env.super_sidebar_enabled? ? super : click_admin_area

          return unless has_text?('Enter Admin Mode', wait: 1.0)

          Admin::NewSession.perform do |new_session|
            new_session.set_password(Runtime::User.admin_password)
            new_session.click_enter_admin_mode
          end
        end

        def signed_in?
          return false if Page::Main::Login.perform(&:on_login_page?)

          has_personal_area?(wait: 0)
        end

        def signed_in_as_user?(user)
          return false unless has_personal_area?

          within_user_menu do
            has_element?(:user_profile_link, text: /#{user.username}/)
          end
          # we need to close user menu because plain user link check will leave it open
          click_element :user_avatar_content if has_element?(:user_profile_link, wait: 0)
        end

        def not_signed_in?
          return true if Page::Main::Login.perform(&:on_login_page?)

          has_no_personal_area?
        end

        def sign_out
          retry_until do
            wait_if_retry_later

            break true unless signed_in?

            within_user_menu do
              click_element :sign_out_link
            end

            not_signed_in?
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
          click_element(Runtime::Env.super_sidebar_enabled? ? :global_search_button : :search_box)
          fill_element(:global_search_input, "#{term}\n")
        end

        def has_personal_area?(wait: Capybara.default_max_wait_time)
          has_element?(:user_avatar_content, wait: wait)
        end

        def has_no_personal_area?(wait: Capybara.default_max_wait_time)
          has_no_element?(:user_avatar_content, wait: wait)
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

        # To verify whether the user has been directed to a canary web node
        # @return [Boolean] result of checking existence of :canary_badge_link element
        # @example:
        #   Menu.perform do |menu|
        #     expect(menu.canary?).to be(true)
        #   end
        def canary?
          has_element?(:canary_badge_link)
        end

        def enable_new_navigation
          Runtime::Logger.info("Enabling super sidebar!")
          return Runtime::Logger.info("User is not signed in, skipping") unless has_element?(:navbar, wait: 2)
          return Runtime::Logger.info("Super sidebar is already enabled") if has_css?('[data-testid="super-sidebar"]')

          within_user_menu { click_element(:new_navigation_toggle) }
        end

        private

        def within_top_menu(&block)
          within_element(:navbar, &block)
        end

        def within_user_menu(&block)
          within_top_menu do
            click_element :user_avatar_content unless has_element?(:user_profile_link, wait: 1)

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
