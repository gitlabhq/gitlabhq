# frozen_string_literal: true

module QA
  module Page
    module Component
      module Placeholders
        module PlaceholdersTable
          extend QA::Page::PageConcern
          include QA::Page::Component::Dropdown

          def self.included(base)
            super

            base.class_eval do
              include ConfirmModal
            end

            base.view 'app/assets/javascripts/members/placeholders/components/placeholders_table.vue' do
              element 'placeholder-status'
              element 'placeholder-reassigned'
            end
          end

          def reassign_placeholder_user(placeholder, username)
            within_element(placeholder.to_s.to_sym) do
              click_element('base-dropdown-toggle')
              wait_for_requests
              search_and_select(username)
              click_element('confirm-button')
            end
          end

          def has_reassignment_status?(placeholder, status, wait: QA::Support::WaitForRequests::DEFAULT_MAX_WAIT_TIME)
            within_element(placeholder.to_s.to_sym) do
              has_element?('placeholder-status', text: status, wait: wait)
            end
          end

          def has_reassigned_user?(placeholder, username, wait: QA::Support::WaitForRequests::DEFAULT_MAX_WAIT_TIME)
            within_element(placeholder.to_s.to_sym) do
              has_element?('placeholder-reassigned', text: username, wait: wait)
            end
          end

          def wait_until_reassignment_completed!
            retry_until(sleep_interval: 10, reload: true, max_attempts: 10) do
              has_element?('gl-empty-state-content')
            end
          end
        end
      end
    end
  end
end
