# frozen_string_literal: true

module Gitlab
  module Tracking
    class EventEligibilityChecker
      def self.only_send_duo_events?
        snowplow_disabled = !Gitlab::CurrentSettings.snowplow_enabled?
        product_usage_data_disabled = !Gitlab::Usage::ProductUsageDataSetting.enabled?

        snowplow_disabled && product_usage_data_disabled
      end

      def self.internal_duo_events
        []
      end

      def eligible?(_event, _app_id = nil)
        snowplow_enabled? || send_usage_data?
      end

      private

      def snowplow_enabled?
        Gitlab::CurrentSettings.snowplow_enabled?
      end

      def send_usage_data?
        Gitlab::Usage::ProductUsageDataSetting.enabled?
      end
    end
  end
end

Gitlab::Tracking::EventEligibilityChecker.prepend_mod
