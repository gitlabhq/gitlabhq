# frozen_string_literal: true

module Gitlab
  module Tracing
    module Rails
      class ActiveRecordSubscriber
        include Gitlab::Tracing::Common

        ACTIVE_RECORD_NOTIFICATION_TOPIC = 'sql.active_record'
        DEFAULT_OPERATION_NAME = "sqlquery"

        def self.instrument
          subscriber = new

          ActiveSupport::Notifications.subscribe(ACTIVE_RECORD_NOTIFICATION_TOPIC) do |_, start, finish, _, payload|
            subscriber.notify(start, finish, payload)
          end
        end

        # For more information on the payloads: https://guides.rubyonrails.org/active_support_instrumentation.html
        def notify(start, finish, payload)
          operation_name = payload[:name].presence || DEFAULT_OPERATION_NAME
          exception = payload[:exception]
          tags = {
            'component' =>        'ActiveRecord',
            'span.kind' =>        'client',
            'db.type' =>          'sql',
            'db.connection_id' => payload[:connection_id],
            'db.cached' =>        payload[:cached] || false,
            'db.statement' =>     payload[:sql]
          }

          postnotify_span("active_record:#{operation_name}", start, finish, tags: tags, exception: exception)
        end
      end
    end
  end
end
