# frozen_string_literal: true

module Gitlab
  module Tracking
    class EventEligibilityChecker
      DUO_EVENTS = %w[
        perform_completion_worker
      ].freeze

      def eligible?(event)
        product_usage_data_enabled? || duo_event?(event)
      end

      private

      def product_usage_data_enabled?
        Gitlab::CurrentSettings.product_usage_data_enabled?
      end

      def duo_event?(event_name)
        DUO_EVENTS.include?(event_name)
      end
    end
  end
end
