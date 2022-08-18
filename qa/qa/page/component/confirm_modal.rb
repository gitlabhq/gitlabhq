# frozen_string_literal: true

module QA
  module Page
    module Component
      module ConfirmModal
        extend QA::Page::PageConcern

        def self.included(base)
          super

          base.view 'app/assets/javascripts/lib/utils/confirm_via_gl_modal/confirm_modal.vue' do
            element :confirm_ok_button
          end

          base.view 'app/assets/javascripts/vue_shared/components/confirm_danger/confirm_danger_modal.vue' do
            element :confirm_danger_modal_button
            element :confirm_danger_field
          end
        end

        def fill_confirmation_text(text)
          fill_element(:confirm_danger_field, text)
        end

        def wait_for_confirm_button_enabled
          wait_until(reload: false) do
            !find_element(:confirm_danger_modal_button).disabled?
          end
        end

        def confirm_transfer
          wait_for_confirm_button_enabled
          click_element(:confirm_danger_modal_button)
        end

        def click_confirmation_ok_button
          click_element(:confirm_ok_button)
        end
      end
    end
  end
end
