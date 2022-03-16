# frozen_string_literal: true

module Gitlab
  module Harbor
    class Client
      Error = Class.new(StandardError)
      ConfigError = Class.new(Error)

      attr_reader :integration

      def initialize(integration)
        raise ConfigError, 'Please check your integration configuration.' unless integration

        @integration = integration
      end

      def ping
        options = { headers: headers.merge!('Accept': 'text/plain') }
        response = Gitlab::HTTP.get(url('ping'), options)

        { success: response.success? }
      end

      private

      def url(path)
        Gitlab::Utils.append_path(base_url, path)
      end

      def base_url
        Gitlab::Utils.append_path(integration.url, '/api/v2.0/')
      end

      def headers
        auth = Base64.strict_encode64("#{integration.username}:#{integration.password}")
        {
          'Content-Type': 'application/json',
          'Authorization': "Basic #{auth}"
        }
      end
    end
  end
end
