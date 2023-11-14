# frozen_string_literal: true

module Gitlab
  module Page
    module Group
      module Settings
        class UsageQuotas < Chemlab::Page
          # Seats section
          div :seats_in_use
          p :seats_used
          p :seats_owed
          table :subscription_users

          # Pipelines section
          link :pipelines_tab
          link :buy_compute_minutes
          div :plan_compute_minutes
          div :additional_compute_minutes
          div :ci_purchase_successful_alert, text: /You have successfully purchased CI minutes/

          # Storage section
          link :storage_tab
          link :purchase_more_storage
          div :namespace_usage_total
          div :group_usage_message
          span :dependency_proxy_size
          div :storage_purchased
          div :storage_purchase_successful_alert, text: /You have successfully purchased a storage/
          span :project_repository_size
          span :project_wiki_size
          span :project_snippets_size
          span :project_containers_registry_size

          # Pending members
          button :view_pending_approvals, text: /View pending approvals/
          div :pending_members_alert
          div :pending_members
          button :approve_member
          button :confirm_member_approval, text: /^OK$/

          def plan_ci_limits
            plan_compute_minutes[/(\d+){2}/]
          end

          def additional_ci_limits
            additional_compute_minutes[/(\d+){2}/]
          end

          def additional_compute_minutes_added?
            #  When opening the Usage quotas page, Seats quota tab is opened briefly even when url is to a different tab
            ::QA::Support::WaitForRequests.wait_for_requests
            additional_compute_minutes?
          end

          # Returns total purchased storage value once it's ready on page
          #
          # @return [Float] Total purchased storage value in GiB
          def total_purchased_storage
            ::QA::Support::WaitForRequests.wait_for_requests

            storage_purchased[/(\d+){2}.\d+/].to_f
          end

          # Waits for additional compute minutes to be available on the page
          def wait_for_additional_compute_minutes_available
            ::QA::Support::Waiter.wait_until(
              max_duration: ::QA::Support::Helpers::Zuora::ZUORA_TIMEOUT,
              sleep_interval: 2,
              reload_page: Chemlab.configuration.browser.session,
              message: 'Expected additional compute minutes but they did not appear.'
            ) do
              additional_compute_minutes_added?
            end
          end

          # Waits for additional compute minutes amount to match the expected number of minutes
          #
          # @param [String] minutes
          def wait_for_additional_compute_minute_limits(minutes)
            wait_for_additional_compute_minutes_available

            ::QA::Support::Waiter.wait_until(
              max_duration: ::QA::Support::Helpers::Zuora::ZUORA_TIMEOUT,
              sleep_interval: 2,
              reload_page: Chemlab.configuration.browser.session,
              message: "Expected additional compute minutes to equal #{minutes}"
            ) do
              additional_ci_limits == minutes
            end
          end
        end
      end
    end
  end
end
