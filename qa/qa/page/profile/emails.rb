# frozen_string_literal: true

module QA
  module Page
    module Profile
      class Emails < Page::Base
        view 'app/views/profiles/emails/index.html.haml' do
          element :email_address_field
          element :add_email_address_button
          element :email_row_content
          element :delete_email_link
        end

        def add_email_address(email_address)
          find_element(:email_address_field).set email_address
          click_element(:add_email_address_button)
        end

        def delete_email_address(email_address)
          page.accept_alert do
            within_element(:email_row_content, text: email_address) do
              click_element(:delete_email_link)
            end
          end
        end
      end
    end
  end
end
