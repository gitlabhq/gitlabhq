# frozen_string_literal: true

module QA
  module Page
    module Profile
      module SuperSidebar
        module Menu
          def click_ssh_keys
            click_element(:sidebar_menu_link, menu_item: 'SSH Keys')
          end

          def click_account
            click_element(:sidebar_menu_link, menu_item: 'Account')
          end

          def click_emails
            click_element(:sidebar_menu_link, menu_item: 'Emails')
          end

          def click_password
            click_element(:sidebar_menu_link, menu_item: 'Password')
          end
        end
      end
    end
  end
end
