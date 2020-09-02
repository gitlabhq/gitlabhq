# frozen_string_literal: true

module Gitlab
  module ErrorTracking
    module Processor
      class GrpcErrorProcessor < ::Raven::Processor
        DEBUG_ERROR_STRING_REGEX = RE2('(.*) debug_error_string:(.*)')

        def process(value)
          return value unless grpc_exception?(value)

          process_message(value)
          process_exception_values(value)
          process_custom_fingerprint(value)

          value
        end

        def grpc_exception?(value)
          value[:exception] && value[:message].start_with?('GRPC::')
        end

        def process_message(value)
          message, debug_str = split_debug_error_string(value[:message])

          return unless message

          value[:message] = message
          extra = value[:extra] || {}
          extra[:grpc_debug_error_string] = debug_str if debug_str
        end

        def process_exception_values(value)
          exceptions = value.dig(:exception, :values)

          return unless exceptions.is_a?(Array)

          exceptions.each do |entry|
            message, _ = split_debug_error_string(entry[:value])
            entry[:value] = message if message
          end
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
