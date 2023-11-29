# frozen_string_literal: true

module BulkImports
  module Clients
    class HTTP
      include Gitlab::Utils::StrongMemoize

      API_VERSION = 'v4'
      DEFAULT_PAGE = 1
      DEFAULT_PER_PAGE = 30
      PAT_ENDPOINT_MIN_VERSION = '15.5.0'
      SIDEKIQ_REQUEST_TIMEOUT = 60

      def initialize(url:, token:, page: DEFAULT_PAGE, per_page: DEFAULT_PER_PAGE, api_version: API_VERSION)
        @url = url
        @token = token&.strip
        @page = page
        @per_page = per_page
        @api_version = api_version
        @compatible_instance_version = false
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
        return to_enum(__method__, method, resource, query) unless block

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

      def instance_version
        Gitlab::VersionInfo.parse(metadata['version'])
      end

      def instance_enterprise
        Gitlab::Utils.to_boolean(metadata['enterprise'], default: true)
      end

      def compatible_for_project_migration?
        instance_version >= BulkImport.min_gl_version_for_project_migration
      end

      def options
        { headers: { 'Content-Type' => 'application/json' }, query: { private_token: @token } }
      end

      def validate_import_scopes!
        return true unless instance_version >= ::Gitlab::VersionInfo.parse(PAT_ENDPOINT_MIN_VERSION)

        response = with_error_handling do
          Gitlab::HTTP.get(resource_url("personal_access_tokens/self"), options)
        end

        return true if response['scopes']&.include?('api')

        raise ::BulkImports::Error.scope_or_url_validation_failure
      end

      def validate_instance_version!
        raise ::BulkImports::Error.invalid_url unless instance_version.valid?

        return true unless instance_version.major < BulkImport::MIN_MAJOR_VERSION

        raise ::BulkImports::Error.unsupported_gitlab_version
      end

      private

      def metadata
        response = begin
          with_error_handling do
            Gitlab::HTTP.get(resource_url(:version), options)
          end
        rescue BulkImports::NetworkError
          # `version` endpoint is not available, try `metadata` endpoint instead
          with_error_handling do
            Gitlab::HTTP.get(resource_url(:metadata), options)
          end
        end

        response.parsed_response
      rescue BulkImports::NetworkError => e
        case e&.response&.code
        when 401, 403
          raise ::BulkImports::Error.scope_or_url_validation_failure
        when 404
          raise ::BulkImports::Error.invalid_url
        else
          raise
        end
      end
      strong_memoize_attr :metadata

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
          query: request_query,
          follow_redirects: true,
          resend_on_redirect: false,
          limit: 2
        }.merge(request_timeout.to_h)
      end

      def request_query
        {
          page: @page,
          per_page: @per_page,
          private_token: @token
        }
      end

      def request_timeout
        { timeout: SIDEKIQ_REQUEST_TIMEOUT } if Gitlab::Runtime.sidekiq?
      end

      # @raise [BulkImports::NetworkError] when unsuccessful
      def with_error_handling
        response = yield

        return response if response.success?

        raise ::BulkImports::NetworkError.new("Unsuccessful response #{response.code} from #{response.request.path.path}. Body: #{response.parsed_response}", response: response)
      rescue *Gitlab::HTTP::HTTP_ERRORS => e
        raise ::BulkImports::NetworkError, e
      end

      def api_url
        Gitlab::Utils.append_path(@url, "/api/#{@api_version}")
      end
    end
  end
end
