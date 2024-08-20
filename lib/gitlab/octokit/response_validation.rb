# frozen_string_literal: true

module Gitlab
  module Octokit
    class ResponseValidation < ::Faraday::Middleware
      MAX_ALLOWED_OBJECTS = 250_000
      MAX_ALLOWED_BYTES = 50.megabytes

      ResponseSizeTooLarge = Class.new(StandardError)

      def on_complete(env)
        body = env.response.body
        return if body.empty?

        raise ResponseSizeTooLarge if body.bytesize > MAX_ALLOWED_BYTES

        parsed_response = Gitlab::Json.parse(body)

        raise ResponseSizeTooLarge if total_object_count(parsed_response) > MAX_ALLOWED_OBJECTS
      rescue JSON::ParserError => e
        Gitlab::ErrorTracking.track_and_raise_for_dev_exception(e)
      end

      private

      def total_object_count(object)
        return 1 unless object.is_a?(Hash) || object.is_a?(Array)

        child_objects = object.is_a?(Hash) ? object.values : object

        1 + child_objects.sum { |v| total_object_count(v) }
      end
    end
  end
end
