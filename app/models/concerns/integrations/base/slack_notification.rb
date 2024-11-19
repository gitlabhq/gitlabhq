# frozen_string_literal: true

module Integrations
  module Base
    module SlackNotification
      extend ActiveSupport::Concern
      extend Gitlab::Utils::Override

      include ChatNotification

      SUPPORTED_EVENTS_FOR_USAGE_LOG = %w[
        push issue confidential_issue merge_request note confidential_note tag_push wiki_page deployment
      ].freeze

      class_methods do
        extend Gitlab::Utils::Override

        override :supported_events
        def supported_events
          super + %w[alert]
        end

        def help
          # noop
        end
      end

      included do
        prop_accessor ChatNotification::EVENT_CHANNEL['alert']
      end

      override :default_channel_placeholder
      def default_channel_placeholder
        _('#general, #development')
      end

      override :get_message
      def get_message(object_kind, data)
        return Integrations::ChatMessage::AlertMessage.new(data) if object_kind == 'alert'

        super
      end

      override :supported_events
      def supported_events
        additional = group_level? ? %w[group_mention group_confidential_mention] : []

        (super + additional).freeze
      end

      override :configurable_channels?
      def configurable_channels?
        true
      end

      private

      override :log_usage
      def log_usage(event, user_id)
        return unless user_id

        return unless SUPPORTED_EVENTS_FOR_USAGE_LOG.include?(event)

        key = "#{metrics_key_prefix}_#{event}_notification"

        Gitlab::UsageDataCounters::HLLRedisCounter.track_event(key, values: user_id)

        optional_arguments = {
          project: project,
          namespace: group || project&.namespace
        }.compact

        Gitlab::Tracking.event(
          self.class.name,
          Integration::SNOWPLOW_EVENT_ACTION,
          label: Integration::SNOWPLOW_EVENT_LABEL,
          property: key,
          user: User.find(user_id),
          context: [Gitlab::Tracking::ServicePingContext.new(data_source: :redis_hll, event: key).to_context],
          **optional_arguments
        )
      end

      def metrics_key_prefix
        raise NotImplementedError
      end
    end
  end
end
