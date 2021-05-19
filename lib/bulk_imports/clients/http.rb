# frozen_string_literal: true

module BulkImports
  module Clients
    class Http
      API_VERSION = 'v4'
      DEFAULT_PAGE = 1
      DEFAULT_PER_PAGE = 30

      ConnectionError = Class.new(StandardError)

      def initialize(uri:, token:, page: DEFAULT_PAGE, per_page: DEFAULT_PER_PAGE, api_version: API_VERSION)
        @uri = URI.parse(uri)
        @token = token&.strip
        @page = page
        @per_page = per_page
        @api_version = api_version
      end

      def get(resource, query = {})
        with_error_handling do
          Gitlab::HTTP.get(
            resource_url(resource),
            headers: request_headers,
            follow_redirects: false,
            query: query.reverse_merge(request_query)
          )
        end
      end

      def post(resource, body = {})
        with_error_handling do
          Gitlab::HTTP.post(
            resource_url(resource),
            headers: request_headers,
            follow_redirects: false,
            body: body
          )
        end
      end

      def each_page(method, resource, query = {}, &block)
        return to_enum(__method__, method, resource, query) unless block_given?

        next_page = @page

        while next_page
          @page = next_page.to_i

          response = self.public_send(method, resource, query) # rubocop: disable GitlabSecurity/PublicSend
          collection = response.parsed_response
          next_page = response.headers['x-next-page'].presence

          yield collection
        end
      end

      private

      def request_query
        {
          page: @page,
          per_page: @per_page
        }
      end

      def request_headers
        {
          'Content-Type' => 'application/json',
          'Authorization' => "Bearer #{@token}"
        }
      end

      def with_error_handling
        response = yield

        raise ConnectionError, "Error #{response.code}" unless response.success?

        response
      rescue *Gitlab::HTTP::HTTP_ERRORS => e
        raise ConnectionError, e
      end

      def base_uri
        @base_uri ||= "#{@uri.scheme}://#{@uri.host}:#{@uri.port}"
      end

      def api_url
        Gitlab::Utils.append_path(base_uri, "/api/#{@api_version}")
      end

      def resource_url(resource)
        Gitlab::Utils.append_path(api_url, resource)
      end
    end
  end
end
