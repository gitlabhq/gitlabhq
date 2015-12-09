module Gitlab
  module Metrics
    module Subscribers
      # Class for tracking method call timings.
      class MethodCall < ActiveSupport::Subscriber
        attach_to :method_call

        SERIES = 'method_calls'

        def instance_method(event)
          return unless current_transaction

          label = "#{event.payload[:module].name}##{event.payload[:name]}"

          add_metric(label, event.duration)
        end

        def class_method(event)
          return unless current_transaction

          label = "#{event.payload[:module].name}.#{event.payload[:name]}"

          add_metric(label, event.duration)
        end

        private

        def add_metric(label, duration)
          file, line = Metrics.last_relative_application_frame

          values = { duration: duration, file: file, line: line }

          current_transaction.add_metric(SERIES, values, method: label)
        end

        def current_transaction
          Transaction.current
        end
      end
    end
  end
end
