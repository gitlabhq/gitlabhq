# frozen_string_literal: true

module Gitlab
  module Tracking
    class EventEligibilityChecker
      EXTERNAL_DUO_EVENTS = {
        'gitlab_ide_extension' => %w[
          click_button
          message_sent
          open_quick_chat
          shortcut
          suggestion_accepted
          suggestion_cancelled
          suggestion_error
          suggestion_loaded
          suggestion_not_provided
          suggestion_rejected
          suggestion_request_rejected
          suggestion_requested
          suggestion_shown
          suggestion_stream_completed
          suggestion_stream_started
        ]
      }.freeze

      INTERNAL_DUO_EVENTS = begin
        Gitlab::Tracking::EventDefinition.definitions.filter_map do |definition|
          definition.action if definition.duo_event?
        end.to_set
      end.freeze

      def eligible?(event, app_id = nil)
        if ::Feature.enabled?(:collect_product_usage_events, :instance)
          snowplow_enabled? || send_usage_data? || duo_event?(event, app_id)
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

      def duo_event?(event_name, app_id)
        if external_service?(app_id)
          external_duo_event?(event_name, app_id)
        else
          INTERNAL_DUO_EVENTS.include?(event_name)
        end
      end

      def external_service?(app_id)
        EXTERNAL_DUO_EVENTS.has_key?(app_id)
      end

      def external_duo_event?(event_name, app_id)
        EXTERNAL_DUO_EVENTS[app_id]&.include?(event_name)
      end
    end
  end
end
