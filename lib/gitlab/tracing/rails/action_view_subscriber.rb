# frozen_string_literal: true

module Gitlab
  module Tracing
    module Rails
      class ActionViewSubscriber
        include RailsCommon

        COMPONENT_TAG = 'ActionView'
        RENDER_TEMPLATE_NOTIFICATION_TOPIC = 'render_template.action_view'
        RENDER_COLLECTION_NOTIFICATION_TOPIC = 'render_collection.action_view'
        RENDER_PARTIAL_NOTIFICATION_TOPIC = 'render_partial.action_view'

        # Instruments Rails ActionView events for opentracing.
        # Returns a lambda, which, when called will unsubscribe from the notifications
        def self.instrument
          subscriber = new

          subscriptions = [
            ActiveSupport::Notifications.subscribe(RENDER_TEMPLATE_NOTIFICATION_TOPIC) do |_, start, finish, _, payload|
              subscriber.notify_render_template(start, finish, payload)
            end,
            ActiveSupport::Notifications.subscribe(RENDER_COLLECTION_NOTIFICATION_TOPIC) do |_, start, finish, _, payload|
              subscriber.notify_render_collection(start, finish, payload)
            end,
            ActiveSupport::Notifications.subscribe(RENDER_PARTIAL_NOTIFICATION_TOPIC) do |_, start, finish, _, payload|
              subscriber.notify_render_partial(start, finish, payload)
            end
          ]

          create_unsubscriber subscriptions
        end

        # For more information on the payloads: https://guides.rubyonrails.org/active_support_instrumentation.html
        def notify_render_template(start, finish, payload)
          generate_span_for_notification("render_template", start, finish, payload, tags_for_render_template(payload))
        end

        def notify_render_collection(start, finish, payload)
          generate_span_for_notification("render_collection", start, finish, payload, tags_for_render_collection(payload))
        end

        def notify_render_partial(start, finish, payload)
          generate_span_for_notification("render_partial", start, finish, payload, tags_for_render_partial(payload))
        end

        private

        def tags_for_render_template(payload)
          {
            'component' =>       COMPONENT_TAG,
            'template.id' =>     payload[:identifier],
            'template.layout' => payload[:layout]
          }
        end

        def tags_for_render_collection(payload)
          {
            'component' =>            COMPONENT_TAG,
            'template.id' =>          payload[:identifier],
            'template.count' =>       payload[:count] || 0,
            'template.cache.hits' =>  payload[:cache_hits] || 0
          }
        end

        def tags_for_render_partial(payload)
          {
            'component' =>            COMPONENT_TAG,
            'template.id' =>          payload[:identifier]
          }
        end
      end
    end
  end
end
