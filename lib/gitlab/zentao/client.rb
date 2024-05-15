# frozen_string_literal: true

module Gitlab
  module Zentao
    class Client
      Error = Class.new(StandardError)
      ConfigError = Class.new(Error)
      RequestError = Class.new(Error)

      CACHE_MAX_SET_SIZE = 5_000
      CACHE_TTL = 1.month.freeze

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
        get("products/#{zentao_product_xid}/issues", params).tap do |response|
          mark_issues_as_seen_in_product(response['issues'])
        end
      end

      def fetch_issue(issue_id)
        raise Error, 'invalid issue id' unless issue_id_pattern.match(issue_id)

        # Only return issues that are associated with the product configured in
        # the integration. Due to a lack of available data in the ZenTao APIs, we
        # can only determine if an issue belongs to a product if the issue was
        # previously returned in the `#fetch_issues` call.
        #
        # See https://gitlab.com/gitlab-org/gitlab/-/issues/360372#note_1016963713
        raise RequestError unless issue_seen_in_product?(issue_id)

        get("issues/#{issue_id}")
      end

      private

      def issue_id_pattern
        /\A\S+-\d+\z/
      end

      def get(path, params = {})
        options = { headers: headers, query: params }
        response = Gitlab::HTTP.get(url(path), options)

        raise RequestError unless response.success?

        Gitlab::Json.parse(response.body)
      rescue JSON::ParserError
        raise Error, 'invalid response format'
      end

      def url(path)
        URI.parse(Gitlab::Utils.append_path(integration.client_url, "api.php/v1/#{path}"))
      end

      def headers
        {
          'Content-Type': 'application/json',
          Token: integration.api_token
        }
      end

      def zentao_product_xid
        integration.zentao_product_xid
      end

      def issue_ids_cache_key
        @issue_ids_cache_key ||= [
          :zentao_product_issues,
          OpenSSL::Digest::SHA256.hexdigest(integration.client_url),
          zentao_product_xid
        ].join(':')
      end

      def issue_ids_cache
        @issue_ids_cache ||= ::Gitlab::SetCache.new(expires_in: CACHE_TTL)
      end

      def mark_issues_as_seen_in_product(issues)
        return unless issues && issue_ids_cache.count(issue_ids_cache_key) < CACHE_MAX_SET_SIZE

        ids = issues.map { _1['id'] }

        issue_ids_cache.write(issue_ids_cache_key, ids)
      end

      def issue_seen_in_product?(id)
        issue_ids_cache.include?(issue_ids_cache_key, id)
      end
    end
  end
end
