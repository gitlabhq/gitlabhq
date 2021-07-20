# frozen_string_literal: true

module Gitlab
  module ErrorTracking
    module Processor
      module GrpcErrorProcessor
        DEBUG_ERROR_STRING_REGEX = RE2('(.*) debug_error_string:(.*)')

        class << self
          def call(event)
            process_first_exception_value(event)
            process_custom_fingerprint(event)

            event
          end

          # Sentry can report multiple exceptions in an event. Sanitize
          # only the first one since that's what is used for grouping.
          def process_first_exception_value(event)
            # Better in new version, will be event.exception.values
            exceptions = event.instance_variable_get(:@interfaces)[:exception]&.values

            return unless exceptions.is_a?(Array)

            exception = exceptions.first

            return unless valid_exception?(exception)

            raw_message = exception.value

            return unless exception.type&.start_with?('GRPC::')
            return unless raw_message.present?

            message, debug_str = split_debug_error_string(raw_message)

            # Worse in new version, no setter! Have to poke at the
            # instance variable
            if message.present?
              exceptions.each do |exception|
                exception.value = message if valid_exception?(exception)
              end
            end

            event.extra[:grpc_debug_error_string] = debug_str if debug_str
          end

          def process_custom_fingerprint(event)
            fingerprint = event.fingerprint

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

          def valid_exception?(exception)
            case exception
            when Raven::SingleExceptionInterface
              exception&.value
            else
              false
            end
          end
        end
      end
    end
  end
end
