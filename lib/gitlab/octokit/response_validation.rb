# frozen_string_literal: true

module Gitlab
  module Octokit
    class ResponseValidation < ::Faraday::Middleware
      ResponseSizeTooLarge = Class.new(StandardError)

      def on_complete(env)
        return if env.url.host == "api.github.com"

        body = env.response.body

        return if body.empty?

        if (max_allowed_bytes != 0 && body.bytesize > max_allowed_bytes) ||
            (max_allowed_values != 0 && total_value_count_estimate(body) > max_allowed_values)
          raise ResponseSizeTooLarge
        end
      end

      private

      # : => Number of key-value pairs
      # , => Number of elements in arrays (off by one since [1, 2, 3] has just 2 commas)
      # [ => Number of arrays
      # { => Number of objects
      def total_value_count_estimate(body)
        body.count("{[,:")
      end

      def max_allowed_bytes
        Gitlab::CurrentSettings.max_github_response_size_limit.megabytes
      end

      def max_allowed_values
        Gitlab::CurrentSettings.max_github_response_json_value_count
      end
    end
  end
end
