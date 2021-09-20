# frozen_string_literal: true

module Gitlab
  module Zentao
    class Client
      Error = Class.new(StandardError)
      ConfigError = Class.new(Error)

      attr_reader :integration

      def initialize(integration)
        raise ConfigError, 'Please check your integration configuration.' unless integration

        @integration = integration
      end

      def ping
        response = fetch_product(zentao_product_xid)

        active = response.fetch('deleted') == '0' rescue false

        if active
          { success: true }
        else
          { success: false, message: 'Not Found' }
        end
      end

      def fetch_product(product_id)
        get("products/#{product_id}")
      end

      def fetch_issues(params = {})
        get("products/#{zentao_product_xid}/issues",
            params.reverse_merge(page: 1, limit: 20))
      end

      def fetch_issue(issue_id)
        get("issues/#{issue_id}")
      end

      private

      def get(path, params = {})
        options = { headers: headers, query: params }
        response = Gitlab::HTTP.get(url(path), options)

        return {} unless response.success?

        Gitlab::Json.parse(response.body)
      rescue JSON::ParserError
        {}
      end

      def url(path)
        host = integration.api_url.presence || integration.url

        URI.join(host, '/api.php/v1/', path)
      end

      def headers
        {
          'Content-Type': 'application/json',
          'Token': integration.api_token
        }
      end

      def zentao_product_xid
        integration.zentao_product_xid
      end
    end
  end
end
