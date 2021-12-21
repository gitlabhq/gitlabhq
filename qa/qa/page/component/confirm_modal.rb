# frozen_string_literal: true

module QA
  module Page
    module Component
      module ConfirmModal
        extend QA::Page::PageConcern

        def self.included(base)
          super
        end

        def fill_confirmation_text(text)
          fill_element :confirm_input, text
        end

        def wait_for_confirm_button_enabled
          wait_until(reload: false) do
            !find_element(:confirm_button).disabled?
          end
        end

        def confirm_transfer
          wait_for_confirm_button_enabled
          click_element :confirm_button
        end
      end
    end
  end
end
