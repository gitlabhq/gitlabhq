# frozen_string_literal: true

module QA
  module Page
    module Component
      module CiBadgeLink
        COMPLETED_STATUSES = %w[passed failed canceled blocked skipped manual].freeze # excludes created, pending, running
        PASSED_STATUS = 'passed'.freeze

        def self.included(base)
          base.view 'app/assets/javascripts/vue_shared/components/ci_badge_link.vue' do
            element :status_badge
          end
        end

        def status_badge
          find_element(:status_badge).text
        end

        def successful?(timeout: 60)
          raise "Timed out waiting for the status to be a valid completed state" unless completed?(timeout: timeout)

          status_badge == PASSED_STATUS
        end

        private

        def completed?(timeout: 60)
          wait_until(reload: false, max_duration: timeout) do
            COMPLETED_STATUSES.include?(status_badge)
          end
        end
      end
    end
  end
end
