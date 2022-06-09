# frozen_string_literal: true

module Gitlab
  module Page
    module Group
      module Settings
        class UsageQuotas < Chemlab::Page
          # TODO: Supplant with data-qa-selectors
          link :pipelines_tab
          link :storage_tab
          link :buy_ci_minutes
          link :buy_storage
          div :plan_ci_minutes
          div :additional_ci_minutes
          span :purchased_usage_total
          div :purchased_usage_total_free, 'data-testid': 'purchased-usage-card' # Different UI for free namespace
          div :ci_purchase_successful_alert, text: /You have successfully purchased CI minutes/
          div :storage_purchase_successful_alert, text: /You have successfully purchased a storage/
          h2 :storage_available_alert, text: /purchased storage is available/

          def plan_ci_limits
            plan_ci_minutes_element.span.text[%r{([^/ ]+)$}]
          end

          def additional_ci_limits
            additional_ci_minutes_element.span.text[%r{([^/ ]+)$}]
          end

          # Waits and Checks if storage available alert presents on the page
          #
          # @return [Boolean] True if the alert presents, false if not after 5 second wait
          def purchased_storage_available?
            storage_available_alert_element.wait_until(timeout: 5, &:present?)
          rescue Watir::Wait::TimeoutError
            false
          end

          # Returns total purchased storage value once it's ready on page
          #
          # @return [Float] Total purchased storage value in GiB
          def total_purchased_storage(free_name_space = true)
            storage_available_alert_element.wait_until(&:present?)

            if free_name_space
              purchased_usage_total_free.split('/').last.match(/\d+\.\d+/)[0].to_f
            else
              purchased_usage_total.to_f
            end
          end
        end
      end
    end
  end
end
