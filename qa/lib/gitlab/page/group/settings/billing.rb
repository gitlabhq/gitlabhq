# frozen_string_literal: true

module Gitlab
  module Page
    module Group
      module Settings
        class Billing < Chemlab::Page
          h4 :billing_plan_header
          link :start_your_free_trial
          link :upgrade_to_premium
          link :upgrade_to_ultimate

          # Subscription details
          strong :subscription_header
          button :refresh_seats

          # Usage
          p :seats_in_subscription
          p :seats_currently_in_use
          link :see_seats_usage
          p :max_seats_used
          p :seats_owed

          # Billing
          p :subscription_start_date
          p :subscription_end_date

          def refresh_subscription_seats
            refresh_seats
            ::QA::Support::WaitForRequests.wait_for_requests
          end

          # Waits for subscription to be synced and UI to be updated
          #
          # @param subscription_plan [String]
          def wait_for_subscription(subscription_plan, page:)
            ::QA::Support::Waiter.wait_until(max_duration: 30, sleep_interval: 2, reload_page: page) do
              billing_plan_header.match?(/currently using the #{subscription_plan} plan/i)
            end
          end
        end
      end
    end
  end
end
