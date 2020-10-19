# frozen_string_literal: true

module Gitlab
  module Middleware
    # There is no valid reason for a request to contain a null byte (U+0000)
    # so just return HTTP 400 (Bad Request) if we receive one
    class HandleNullBytes
      NULL_BYTE_REGEX = Regexp.new(Regexp.escape("\u0000")).freeze

      attr_reader :app

      def initialize(app)
        @app = app
      end

      def call(env)
        return [400, {}, ["Bad Request"]] if request_has_null_byte?(env)

        app.call(env)
      end

      private

      def request_has_null_byte?(request)
        return false if ENV['REJECT_NULL_BYTES'] == "1"

        request = Rack::Request.new(request)

        request.params.values.any? do |value|
          param_has_null_byte?(value)
        end
      end

      def param_has_null_byte?(value, depth = 0)
        # Guard against possible attack sending large amounts of nested params
        # Should be safe as deeply nested params are highly uncommon.
        return false if depth > 2

        depth += 1

        if value.respond_to?(:match)
          string_contains_null_byte?(value)
        elsif value.respond_to?(:values)
          value.values.any? do |hash_value|
            param_has_null_byte?(hash_value, depth)
          end
        elsif value.is_a?(Array)
          value.any? do |array_value|
            param_has_null_byte?(array_value, depth)
          end
        else
          false
        end
      end

      def string_contains_null_byte?(string)
        string.match?(NULL_BYTE_REGEX)
      end
    end
  end
end
