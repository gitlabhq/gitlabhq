# frozen_string_literal: true

module BulkImports
  module Clients
    class HTTP
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
        request(:get, resource, query: query.reverse_merge(request_query))
      end

      def post(resource, body = {})
        request(:post, resource, body: body)
      end

      def head(resource)
        request(:head, resource)
      end

      def stream(resource, &block)
        request(:get, resource, stream_body: true, &block)
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

      def resource_url(resource)
        Gitlab::Utils.append_path(api_url, resource)
      end

      private

      # rubocop:disable GitlabSecurity/PublicSend
      def request(method, resource, options = {}, &block)
        with_error_handling do
          Gitlab::HTTP.public_send(
            method,
            resource_url(resource),
            request_options(options),
            &block
          )
        end
      end
      # rubocop:enable GitlabSecurity/PublicSend

      def request_options(options)
        default_options.merge(options)
      end

      def default_options
        {
          headers: request_headers,
          follow_redirects: false
        }
      end

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
    end
  end
end
