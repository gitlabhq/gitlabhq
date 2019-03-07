# frozen_string_literal: true

module Gitlab
  module Tracing
    module Rails
      class ActiveRecordSubscriber
        include RailsCommon

        ACTIVE_RECORD_NOTIFICATION_TOPIC = 'sql.active_record'
        OPERATION_NAME_PREFIX = 'active_record:'
        DEFAULT_OPERATION_NAME = 'sqlquery'

        # Instruments Rails ActiveRecord events for opentracing.
        # Returns a lambda, which, when called will unsubscribe from the notifications
        def self.instrument
          subscriber = new

          subscription = ActiveSupport::Notifications.subscribe(ACTIVE_RECORD_NOTIFICATION_TOPIC) do |_, start, finish, _, payload|
            subscriber.notify(start, finish, payload)
          end

          create_unsubscriber [subscription]
        end

        # For more information on the payloads: https://guides.rubyonrails.org/active_support_instrumentation.html
        def notify(start, finish, payload)
          generate_span_for_notification(notification_name(payload), start, finish, payload, tags_for_notification(payload))
        end

        private

        def notification_name(payload)
          OPERATION_NAME_PREFIX + (payload[:name].presence || DEFAULT_OPERATION_NAME)
        end

        def tags_for_notification(payload)
          {
            'component' =>        'ActiveRecord',
            'span.kind' =>        'client',
            'db.type' =>          'sql',
            'db.connection_id' => payload[:connection_id],
            'db.cached' =>        payload[:cached] || false,
            'db.statement' =>     payload[:sql]
          }
        end
      end
    end
  end
end
