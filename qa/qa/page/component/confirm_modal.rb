# frozen_string_literal: true

module QA
  module Page
    module Component
      module ConfirmModal
        extend QA::Page::PageConcern

        def self.included(base)
          super

          base.view 'app/views/shared/_confirm_modal.html.haml' do
            element :confirm_modal
            element :confirm_input
            element :confirm_button
          end
        end

        def fill_confirmation_text(text)
          fill_element :confirm_input, text
        end

        def click_confirm_button
          click_element :confirm_button
        end
      end
    end
  end
end
