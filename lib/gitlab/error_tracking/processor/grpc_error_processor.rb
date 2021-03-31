# frozen_string_literal: true

module Gitlab
  module ErrorTracking
    module Processor
      class GrpcErrorProcessor < ::Raven::Processor
        DEBUG_ERROR_STRING_REGEX = RE2('(.*) debug_error_string:(.*)')

        def process(payload)
          return payload if ::Feature.enabled?(:sentry_processors_before_send, default_enabled: :yaml)

          self.class.process_first_exception_value(payload)
          self.class.process_custom_fingerprint(payload)

          payload
        end

        class << self
          def call(event)
            return event unless ::Feature.enabled?(:sentry_processors_before_send, default_enabled: :yaml)

            process_first_exception_value(event)
            process_custom_fingerprint(event)

            event
          end

          # Sentry can report multiple exceptions in an event. Sanitize
          # only the first one since that's what is used for grouping.
          def process_first_exception_value(event_or_payload)
            exceptions = exceptions(event_or_payload)

            return unless exceptions.is_a?(Array)

            exception = exceptions.first

            return unless valid_exception?(exception)

            exception_type, raw_message = type_and_value(exception)

            return unless exception_type&.start_with?('GRPC::')
            return unless raw_message.present?

            message, debug_str = split_debug_error_string(raw_message)

            set_new_values!(event_or_payload, exception, message, debug_str)
          end

          def process_custom_fingerprint(event)
            fingerprint = fingerprint(event)

            return event unless custom_grpc_fingerprint?(fingerprint)

            message, _ = split_debug_error_string(fingerprint[1])
            fingerprint[1] = message if message
          end

          private

          def custom_grpc_fingerprint?(fingerprint)
            fingerprint.is_a?(Array) && fingerprint.length == 2 && fingerprint[0].start_with?('GRPC::')
          end

          def split_debug_error_string(message)
            return unless message

            match = DEBUG_ERROR_STRING_REGEX.match(message)

            return unless match

            [match[1], match[2]]
          end

          # The below methods can be removed once we remove the
          # sentry_processors_before_send feature flag, and we can
          # assume we always have an Event object
          def exceptions(event_or_payload)
            case event_or_payload
            when Raven::Event
              # Better in new version, will be event_or_payload.exception.values
              event_or_payload.instance_variable_get(:@interfaces)[:exception]&.values
            when Hash
              event_or_payload.dig(:exception, :values)
            end
          end

          def valid_exception?(exception)
            case exception
            when Raven::SingleExceptionInterface
              exception&.value
            when Hash
              true
            else
              false
            end
          end

          def type_and_value(exception)
            case exception
            when Raven::SingleExceptionInterface
              [exception.type, exception.value]
            when Hash
              exception.values_at(:type, :value)
            end
          end

          def set_new_values!(event_or_payload, exception, message, debug_str)
            case event_or_payload
            when Raven::Event
              # Worse in new version, no setter! Have to poke at the
              # instance variable
              exception.value = message if message
              event_or_payload.extra[:grpc_debug_error_string] = debug_str if debug_str
            when Hash
              exception[:value] = message if message
              extra = event_or_payload[:extra] || {}
              extra[:grpc_debug_error_string] = debug_str if debug_str
            end
          end

          def fingerprint(event_or_payload)
            case event_or_payload
            when Raven::Event
              event_or_payload.fingerprint
            when Hash
              event_or_payload[:fingerprint]
            end
          end
        end
      end
    end
  end
end
