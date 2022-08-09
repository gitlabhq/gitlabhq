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
        response = begin
          fetch_product(zentao_product_xid)
        rescue StandardError
          {}
        end
        active = response['deleted'] == '0'
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
        get("products/#{zentao_product_xid}/issues", params)
      end

      def fetch_issue(issue_id)
        raise Gitlab::Zentao::Client::Error, 'invalid issue id' unless issue_id_pattern.match(issue_id)

        get("issues/#{issue_id}")
      end

      private

      def issue_id_pattern
        /\A\S+-\d+\z/
      end

      def get(path, params = {})
        options = { headers: headers, query: params }
        response = Gitlab::HTTP.get(url(path), options)

        raise Gitlab::Zentao::Client::Error, 'request error' unless response.success?

        Gitlab::Json.parse(response.body)
      rescue JSON::ParserError
        raise Gitlab::Zentao::Client::Error, 'invalid response format'
      end

      def url(path)
        host = integration.api_url.presence || integration.url

        URI.parse(Gitlab::Utils.append_path(host, "api.php/v1/#{path}"))
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
