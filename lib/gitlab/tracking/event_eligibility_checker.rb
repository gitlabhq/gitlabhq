# frozen_string_literal: true

module Gitlab
  module Tracking
    class EventEligibilityChecker
      def eligible?(_event, _app_id = nil)
        if ::Feature.enabled?(:collect_product_usage_events, :instance)
          snowplow_enabled? || send_usage_data?
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
    end
  end
end

Gitlab::Tracking::EventEligibilityChecker.prepend_mod
