# frozen_string_literal: true

module QA
  module Page
    module Profile
      class Menu < Page::Base
        prepend QA::Mobile::Page::SubMenus::Common if QA::Runtime::Env.mobile_layout?
        # TODO: integrate back once super sidebar becomes default
        prepend QA::Page::Profile::SuperSidebar::Menu if QA::Runtime::Env.super_sidebar_enabled?

        view 'lib/sidebars/user_settings/menus/access_tokens_menu.rb' do
          element :access_token_link
        end

        view 'lib/sidebars/user_settings/menus/ssh_keys_menu.rb' do
          element :ssh_keys_link
        end

        view 'lib/sidebars/user_settings/menus/emails_menu.rb' do
          element :profile_emails_link
        end

        view 'lib/sidebars/user_settings/menus/password_menu.rb' do
          element :profile_password_link
        end

        view 'lib/sidebars/user_settings/menus/account_menu.rb' do
          element :profile_account_link
        end

        def click_access_tokens
          within_sidebar do
            click_element(:access_token_link)
          end
        end

        def click_ssh_keys
          within_sidebar do
            click_element(:ssh_keys_link)
          end
        end

        def click_account
          within_sidebar do
            click_element(:profile_account_link)
          end
        end

        def click_emails
          within_sidebar do
            click_element(:profile_emails_link)
          end
        end

        def click_password
          within_sidebar do
            click_element(:profile_password_link)
          end
        end

        private

        def within_sidebar(&block)
          page.within('.sidebar-top-level-items', &block)
        end
      end
    end
  end
end

QA::Page::Profile::Menu.prepend_mod_with('Page::Profile::Menu', namespace: QA)
