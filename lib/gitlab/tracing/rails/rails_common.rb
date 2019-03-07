# frozen_string_literal: true

module Gitlab
  module Tracing
    module Rails
      module RailsCommon
        extend ActiveSupport::Concern
        include Gitlab::Tracing::Common

        class_methods do
          def create_unsubscriber(subscriptions)
            -> { subscriptions.each { |subscriber| ActiveSupport::Notifications.unsubscribe(subscriber) } }
          end
        end

        def generate_span_for_notification(operation_name, start, finish, payload, tags)
          exception = payload[:exception]

          postnotify_span(operation_name, start, finish, tags: tags, exception: exception)
        end
      end
    end
  end
end
