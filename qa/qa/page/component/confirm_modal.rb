# frozen_string_literal: true

module QA
  module Page
    module Component
      module ConfirmModal
        extend QA::Page::PageConcern

        def self.included(base)
          super

          base.view 'app/assets/javascripts/lib/utils/confirm_via_gl_modal/confirm_modal.vue' do
            element 'confirm-ok-button'
            element 'confirmation-modal'
          end

          base.view 'app/assets/javascripts/vue_shared/components/confirm_danger/confirm_danger_modal.vue' do
            element 'confirm-danger-modal-button'
            element 'confirm-danger-field'
          end
        end

        def fill_confirmation_text(text)
          fill_element('confirm-danger-field', text)
        end

        def wait_for_confirm_button_enabled
          wait_until(reload: false) do
            !find_element('confirm-danger-modal-button').disabled?
          end
        end

        def confirm_transfer
          wait_for_confirm_button_enabled
          click_element('confirm-danger-modal-button')
        end

        def click_confirmation_ok_button
          click_element('confirm-ok-button')
        end

        # Click the confirmation button if the confirmation modal is present
        # Can be used when the modal may not always appear in a test. For example, if the modal is behind a feature flag
        #
        # @return [void]
        def click_confirmation_ok_button_if_present
          # In the case of changing access levels[1], the modal appears while there's a request in process, so we need
          # to skip the loading check otherwise it will time out.
          #
          # [1]: https://gitlab.com/gitlab-org/gitlab/-/blob/4a99af809b86047ce3c8985e6582748bbd23fc84/qa/qa/page/component/members/members_table.rb#L54
          return unless has_element?('confirmation-modal', skip_finished_loading_check: true)

          click_element('confirm-ok-button', skip_finished_loading_check: true)
        end
      end
    end
  end
end
