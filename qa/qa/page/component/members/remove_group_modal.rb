# frozen_string_literal: true

module QA
  module Page
    module Component
      module Members
        module RemoveGroupModal
          extend QA::Page::PageConcern

          def self.included(base)
            super

            base.view 'app/assets/javascripts/members/components/modals/remove_group_link_modal.vue' do
              element :remove_group_link_modal_content
              element :remove_group_button
            end
          end

          def confirm_remove_group
            within_element(:remove_group_link_modal_content) do
              wait_for_enabled_remove_group_button

              click_element :remove_group_button
            end
          end

          private

          def wait_for_enabled_remove_group_button
            retry_until(sleep_interval: 1, message: 'Waiting for remove group button to be enabled') do
              has_element?(:remove_group_button, disabled: false, wait: 3)
            end
          end
        end
      end
    end
  end
end
