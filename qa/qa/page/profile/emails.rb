# frozen_string_literal: true

module QA
  module Page
    module Profile
      class Emails < Page::Base
        include QA::Page::Component::ConfirmModal

        view 'app/views/profiles/emails/index.html.haml' do
          element :email_address_field
          element :add_email_address_button
          element :email_row_content
          element :delete_email_link
          element :toggle_email_address_field
        end

        def expand_email_input
          click_element(:toggle_email_address_field) if has_no_element?(:email_address_field)
          has_element?(:email_address_field)
        end

        def add_email_address(email_address)
          expand_email_input
          find_element(:email_address_field).set email_address
          click_element(:add_email_address_button)
        end

        def delete_email_address(email_address)
          within_element(:email_row_content, text: email_address) do
            click_element(:delete_email_link)
          end
          click_confirmation_ok_button
        end
      end
    end
  end
end
