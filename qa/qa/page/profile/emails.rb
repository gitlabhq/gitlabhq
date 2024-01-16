# frozen_string_literal: true

module QA
  module Page
    module Profile
      class Emails < Page::Base
        include QA::Page::Component::ConfirmModal

        view 'app/views/profiles/emails/index.html.haml' do
          element 'email-address-field'
          element 'add-email-address-button'
          element 'email-row-content'
          element 'delete-email-link'
          element 'toggle-email-address-field'
        end

        def expand_email_input
          click_element('toggle-email-address-field') if has_no_element?('email-address-field')
          has_element?('email-address-field')
        end

        def add_email_address(email_address)
          expand_email_input
          find_element('email-address-field').set email_address
          click_element('add-email-address-button')
        end

        def delete_email_address(email_address)
          within_element('email-row-content', text: email_address) do
            click_element('delete-email-link')
          end
          click_confirmation_ok_button
        end
      end
    end
  end
end
