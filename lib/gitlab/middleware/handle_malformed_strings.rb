# frozen_string_literal: true

module Gitlab
  module Middleware
    # There is no valid reason for a request to contain a malformed string
    # so just return HTTP 400 (Bad Request) if we receive one
    class HandleMalformedStrings
      include ActionController::HttpAuthentication::Basic

      NULL_BYTE_REGEX = Regexp.new(Regexp.escape("\u0000")).freeze

      attr_reader :app

      def initialize(app)
        @app = app
      end

      def call(env)
        return [400, { 'Content-Type' => 'text/plain' }, ['Bad Request']] if request_contains_malformed_string?(env)

        app.call(env)
      end

      private

      def request_contains_malformed_string?(env)
        return false if ENV['DISABLE_REQUEST_VALIDATION'] == '1'

        # Duplicate the env, so it is not modified when accessing the parameters
        # https://github.com/rails/rails/blob/34991a6ae2fc68347c01ea7382fa89004159e019/actionpack/lib/action_dispatch/http/parameters.rb#L59
        # The modification causes problems with our multipart middleware
        request = ActionDispatch::Request.new(env.dup)

        return true if malformed_path?(request.path)
        return true if credentials_malformed?(request)

        request.params.values.any? do |value|
          param_has_null_byte?(value)
        end
      rescue ActionController::BadRequest, ActionDispatch::Http::Parameters::ParseError
        # If we can't build an ActionDispatch::Request something's wrong
        # This would also happen if `#params` contains invalid UTF-8
        # in this case we'll return a 400
        #
        true
      end

      def malformed_path?(path)
        string_malformed?(Rack::Utils.unescape(path))
      rescue ArgumentError
        # Rack::Utils.unescape raised this, path is malformed.
        true
      end

      def credentials_malformed?(request)
        credentials = if has_basic_credentials?(request)
                        decode_credentials(request).presence
                      else
                        request.authorization.presence
                      end

        return false unless credentials

        string_malformed?(credentials)
      end

      def param_has_null_byte?(value, depth = 0)
        # Guard against possible attack sending large amounts of nested params
        # Should be safe as deeply nested params are highly uncommon.
        return false if depth > 2

        depth += 1

        if value.respond_to?(:match)
          string_malformed?(value)
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

      def string_malformed?(string)
        # We're using match rather than include, because that will raise an ArgumentError
        # when  the string contains invalid UTF8
        #
        # We try to encode the string from ASCII-8BIT to UTF8. If we failed to do
        # so for certain characters in the string, those chars are probably incomplete
        # multibyte characters.
        string.dup.force_encoding(Encoding::UTF_8).match?(NULL_BYTE_REGEX)

      rescue ArgumentError, Encoding::UndefinedConversionError
        # If we're here, we caught a malformed string. Return true
        true
      end
    end
  end
end
