# frozen_string_literal: true

module Gitlab
  module Page
    module Group
      module Settings
        class UsageQuotas < Chemlab::Page
          # Seats section
          link :seats_tab
          div :seats_in_use
          p :seats_used
          p :seats_owed
          table :subscription_users
          div :pending_members_alert
          button :remove_user
          button :view_pending_approvals, text: /View pending approvals/

          # Pipelines section
          link :pipelines_tab
          link :buy_ci_minutes
          div :plan_ci_minutes
          div :additional_ci_minutes
          div :ci_purchase_successful_alert, text: /You have successfully purchased CI minutes/

          # Storage section
          link :storage_tab
          link :purchase_more_storage
          div :namespace_usage_total
          div :group_usage_message
          div :dependency_proxy_usage
          span :dependency_proxy_size
          div :container_registry_usage
          div :project
          div :storage_type_legend
          span :container_registry_size
          div :purchased_usage_total
          div :storage_purchase_successful_alert, text: /You have successfully purchased a storage/
          div :additional_storage_alert, text: /purchase additional storage/

          # Pending members
          div :pending_members
          button :approve_member
          button :confirm_member_approval, text: /^OK$/

          def plan_ci_limits
            plan_ci_minutes[/(\d+){2}/]
          end

          def additional_ci_limits
            additional_ci_minutes[/(\d+){2}/]
          end

          # Waits and Checks if storage available alert presents on the page
          #
          # @return [Boolean] True if the alert presents, false if not after 5 second wait
          def additional_storage_available?
            additional_storage_alert_element.wait_until(timeout: 5, &:present?)
          rescue Watir::Wait::TimeoutError
            false
          end

          # Waits and Checks if storage project data loaded
          #
          # @return [Boolean] True if the alert presents, false if not after 5 second wait
          def project_storage_data_available?
            storage_type_legend_element.wait_until(timeout: 3, &:present?)
          rescue Watir::Wait::TimeoutError
            false
          end

          # Returns total purchased storage value once it's ready on page
          #
          # @return [Float] Total purchased storage value in GiB
          def total_purchased_storage
            additional_storage_alert_element.wait_until(&:present?)

            purchased_usage_total[/(\d+){2}.\d+/].to_f
          end

          def additional_ci_minutes_added?
            # When opening the Usage quotas page, Seats quota tab is opened briefly even when url is to a different tab
            ::QA::Support::WaitForRequests.wait_for_requests
            additional_ci_minutes?
          end
        end
      end
    end
  end
end
