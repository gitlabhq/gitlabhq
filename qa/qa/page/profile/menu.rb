# frozen_string_literal: true

module QA
  module Page
    module Profile
      class Menu < Page::Base
        include SubMenus::CreateNewMenu

        def click_ssh_keys
          open_access_submenu('SSH keys')
        end

        def click_account
          click_element('nav-item-link', submenu_item: 'Account')
        end

        def click_emails
          click_element('nav-item-link', submenu_item: 'Emails')
        end

        def click_password
          open_access_submenu('Password')
        end

        def click_personal_access_tokens
          open_access_submenu('Personal access tokens')
        end

        private

        def open_access_submenu(sub_menu)
          open_submenu('Access', sub_menu)
        end
      end
    end
  end
end

QA::Page::Profile::Menu.prepend_mod_with('Page::Profile::Menu', namespace: QA)
