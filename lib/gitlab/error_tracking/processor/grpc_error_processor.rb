# frozen_string_literal: true

module Gitlab
  module ErrorTracking
    module Processor
      class GrpcErrorProcessor < ::Raven::Processor
        DEBUG_ERROR_STRING_REGEX = RE2('(.*) debug_error_string:(.*)')

        def process(value)
          process_first_exception_value(value)
          process_custom_fingerprint(value)

          value
        end

        # Sentry can report multiple exceptions in an event. Sanitize
        # only the first one since that's what is used for grouping.
        def process_first_exception_value(value)
          exceptions = value.dig(:exception, :values)

          return unless exceptions.is_a?(Array)

          entry = exceptions.first

          return unless entry.is_a?(Hash)

          exception_type = entry[:type]
          raw_message = entry[:value]

          return unless exception_type&.start_with?('GRPC::')
          return unless raw_message.present?

          message, debug_str = split_debug_error_string(raw_message)

          entry[:value] = message if message
          extra = value[:extra] || {}
          extra[:grpc_debug_error_string] = debug_str if debug_str
        end

        def process_custom_fingerprint(value)
          fingerprint = value[:fingerprint]

          return value unless custom_grpc_fingerprint?(fingerprint)

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
      end
    end
  end
end
