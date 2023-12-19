# frozen_string_literal: true

module QA
  module Page
    module Component
      module DeleteModal
        extend QA::Page::PageConcern

        def self.included(base)
          super

          base.view 'app/assets/javascripts/projects/components/shared/delete_modal.vue' do
            element 'confirm-name-field'
            element 'confirm-delete-button'
          end
        end

        def fill_confirmation_path(text)
          fill_element('confirm-name-field', text)
        end

        def wait_for_delete_button_enabled
          wait_until(reload: false) do
            !find_element('confirm-delete-button').disabled?
          end
        end

        def confirm_delete
          wait_for_delete_button_enabled
          click_element('confirm-delete-button')
        end
      end
    end
  end
end
