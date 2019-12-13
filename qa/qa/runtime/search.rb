# frozen_string_literal: true

module QA
  module Runtime
    module Search
      extend self
      extend Support::Api

      ElasticSearchServerError = Class.new(RuntimeError)

      def elasticsearch_responding?
        QA::Runtime::Logger.debug("Attempting to search via Elasticsearch...")

        QA::Support::Retrier.retry_on_exception do
          # We don't care about the results of the search, we just need
          # any search that uses Elasticsearch, not the native search
          # The Elasticsearch-only scopes are blobs, wiki_blobs, and commits.
          request = Runtime::API::Request.new(api_client, "/search?scope=blobs&search=foo")
          response = get(request.url)

          unless response.code == singleton_class::HTTP_STATUS_OK
            raise ElasticSearchServerError, "Search attempt failed. Request returned (#{response.code}): `#{response}`."
          end

          true
        end
      end

      private

      def api_client
        @api_client ||= Runtime::API::Client.new(:gitlab)
      end
    end
  end
end
