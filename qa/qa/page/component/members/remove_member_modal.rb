# frozen_string_literal: true

module QA
  module Page
    module Component
      module Members
        module RemoveMemberModal
          extend QA::Page::PageConcern

          def self.included(base)
            super

            base.view 'app/assets/javascripts/members/components/modals/remove_member_modal.vue' do
              element :remove_member_modal
              element :remove_member_button
            end
          end

          def confirm_remove_member
            within_element(:remove_member_modal) do
              wait_for_enabled_remove_member_button

              click_element :remove_member_button
            end
          end

          private

          def wait_for_enabled_remove_member_button
            retry_until(sleep_interval: 1, message: 'Waiting for remove member button to be enabled') do
              has_element?(:remove_member_button, disabled: false, wait: 3)
            end
          end
        end
      end
    end
  end
end
