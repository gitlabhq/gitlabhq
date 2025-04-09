# frozen_string_literal: true

module Gitlab
  module Tracking
    class EventEligibilityChecker
      DUO_EVENTS = %w[
        perform_completion_worker
      ].freeze

      def eligible?(event)
        if ::Feature.enabled?('collect_product_usage_events', :instance)
          snowplow_enabled? || send_usage_data? || duo_event?(event)
        else
          snowplow_enabled?
        end
      end

      private

      def snowplow_enabled?
        Gitlab::CurrentSettings.snowplow_enabled?
      end

      def send_usage_data?
        Gitlab::CurrentSettings.gitlab_product_usage_data_enabled?
      end

      def duo_event?(event_name)
        DUO_EVENTS.include?(event_name)
      end
    end
  end
end
