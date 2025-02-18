# frozen_string_literal: true

require 'active_support/core_ext/object/deep_dup'
require 'capybara/dsl'

module QA
  module Resource
    module ApiFabricator
      include Capybara::DSL
      include Support::API
      include Errors

      attr_reader :api_fabrication_http_method
      attr_writer :api_client
      attr_accessor :api_resource, :api_response

      def api_support?
        (defines_get? && defines_post?) || defines_put?
      end

      # @return [String] the resource web url
      def fabricate_via_api!
        unless api_support?
          raise NotImplementedError, "Resource #{self.class.name} does not support fabrication via the API!"
        end

        resource_web_url = resource_web_url(api_post)
        wait_for_resource_availability(resource_web_url)

        resource_web_url
      end

      def reload!
        api_get

        self
      end

      def remove_via_api!
        api_delete
      end

      # Checks if a resource already exists
      #
      # @return [Boolean] true if the resource returns HTTP status code 200
      def exists?(**args)
        request = Runtime::API::Request.new(api_client, api_get_path)
        response = get(request.url, args)

        response.code == HTTP_STATUS_OK
      end

      # Parameters included in the query URL
      #
      # @return [Hash]
      def query_parameters
        @query_parameters ||= {}
      end

      private

      def defines_get?
        respond_to?(:api_get_path)
      end

      def defines_post?
        respond_to?(:api_post_path) && respond_to?(:api_post_body)
      end

      def defines_put?
        respond_to?(:api_put_path) && respond_to?(:api_put_body)
      end

      # rubocop:disable Gitlab/ModuleWithInstanceVariables -- QA::Resource::Base specific implementation
      def api_get
        process_api_response(parse_body(api_get_from(api_get_path))).tap do
          # Record method that was used to create certain resource
          #  :get - resource already existed in GitLab instance and was fetched via get request
          #  :post - resource was created from scratch using post request
          #  :put - resource was created from scratch using put request
          @api_fabrication_http_method ||= :get
        end
      end

      # TODO: remove global query_parameters so this helper method does not depend on global variable
      # It assumes that all resource related might have a common query which often is not the case
      def api_get_from(get_path, q_params: query_parameters)
        path = "#{get_path}#{query_parameters_to_string(q_params)}"
        request = Runtime::API::Request.new(api_client, path)
        response = get(request.url)

        if response.code == HTTP_STATUS_NOT_FOUND
          raise(ResourceNotFoundError, <<~MSG.strip)
            Resource at #{request.mask_url} could not be found (#{response.code}): `#{response}`.
            #{QA::Support::Loglinking.failure_metadata(response.headers[:x_request_id])}
          MSG
        elsif !success?(response.code)
          raise(InternalServerError, <<~MSG.strip)
            Failed to GET #{request.mask_url} - (#{response.code}): `#{response}`.
            #{QA::Support::Loglinking.failure_metadata(response.headers[:x_request_id])}
          MSG
        end

        response
      end

      def api_post
        process_api_response(api_post_to(api_post_path, api_post_body)).tap do
          @api_fabrication_http_method ||= :post
        end
      end

      def api_post_to(post_path, post_body, args = {})
        if post_path == "/graphql"
          payload = post_body.is_a?(String) ? { query: post_body } : post_body
          graphql_response = post(Runtime::API::Request.new(api_client, post_path).url, payload, args)

          body = extract_graphql_body(graphql_response)

          unless graphql_response.code == HTTP_STATUS_OK && body[:errors].blank?
            action = /mutation {\s+destroy/.match?(post_body) ? 'Deletion' : 'Fabrication'
            raise(ResourceFabricationFailedError, <<~MSG.strip)
              #{action} of #{self.class.name} using the API failed (#{graphql_response.code}) with `#{graphql_response}`.
              #{QA::Support::Loglinking.failure_metadata(graphql_response.headers[:x_request_id])}
            MSG
          end

          body[:id] = extract_graphql_id(body) if body.key?(:id)
          body.deep_transform_keys { |key| key.to_s.underscore.to_sym }
        else
          response = post(Runtime::API::Request.new(api_client, post_path).url, post_body, args)

          unless response.code == post_success_response_code
            raise(ResourceFabricationFailedError, <<~MSG.strip)
              Fabrication of #{self.class.name} using the API failed (#{response.code}) with `#{response}`.
              #{QA::Support::Loglinking.failure_metadata(response.headers[:x_request_id])}
            MSG
          end

          parse_body(response)
        end
      end

      def api_put
        process_api_response(api_put_to(api_put_path, api_put_body)).tap do
          @api_fabrication_http_method ||= :put
        end
      end

      def api_put_to(put_path, body)
        response = put(Runtime::API::Request.new(api_client, put_path).url, body)

        unless response.code == HTTP_STATUS_OK
          raise(ResourceFabricationFailedError, <<~MSG.strip)
            Updating #{self.class.name} using the API failed (#{response.code}) with `#{response}`.
            #{QA::Support::Loglinking.failure_metadata(response.headers[:x_request_id])}
          MSG
        end

        parse_body(response)
      end

      def api_delete
        if api_delete_path == "/graphql"
          api_post_to(api_delete_path, api_delete_body)
        else
          request = Runtime::API::Request.new(api_client, api_delete_path)
          response = delete(request.url, payload: api_delete_body)

          unless [HTTP_STATUS_NO_CONTENT, HTTP_STATUS_ACCEPTED].include? response.code
            raise(ResourceNotDeletedError, <<~MSG.strip)
              Resource at #{request.mask_url} could not be deleted (#{response.code}): `#{response}`.
              #{QA::Support::Loglinking.failure_metadata(response.headers[:x_request_id])}
            MSG
          end

          response
        end
      end

      def resource_web_url(resource)
        resource.fetch(:web_url) do
          raise ResourceURLMissingError,
            "API resource for #{self.class.name} does not expose a `web_url` property: `#{resource}`."
        end
      end

      # Api client to use for fabrications by default
      #
      # @return [QA::Runtime::API::Client]
      def api_client
        @api_client ||= Runtime::User::Store.default_api_client
      end
      # rubocop:enable Gitlab/ModuleWithInstanceVariables

      def process_api_response(parsed_response)
        self.api_response = parsed_response
        self.api_resource = transform_api_resource(parsed_response.deep_dup)
      end

      def transform_api_resource(api_resource)
        api_resource
      end

      # Get api request url
      #
      # @param [String] path
      # @return [String]
      def request_url(path, **opts)
        Runtime::API::Request.new(api_client, path, **opts).url
      end

      # Query parameters formatted as `?key1=value1&key2=value2...`
      #
      # @param parameters [Hash<String, String>]
      # @return [String]
      def query_parameters_to_string(parameters)
        parameters.each_with_object([]) do |(k, v), arr|
          arr << "#{k}=#{v}"
        end.join('&').prepend('?').chomp('?') # prepend `?` unless the string is blank
      end

      def extract_graphql_body(graphql_response)
        parsed_body = parse_body(graphql_response)
        return parsed_body if parsed_body[:errors].present?

        data = Hash[parsed_body.values[0]]
        Hash[data.values[0]]
      end

      # Given a URL, wait for the given URL to return 200
      # @param [String] resource_web_url the URL to check
      # @example
      #   wait_for_resource_availability('https://gitlab.com/api/v4/projects/1234')
      # @example
      #   wait_for_resource_availability(resource_web_url(create(:issue)))
      def wait_for_resource_availability(resource_web_url)
        return unless Runtime::Address.valid?(resource_web_url)

        Support::Retrier.retry_until(sleep_interval: 3, max_attempts: 5, raise_on_failure: false) do
          response_check = get(resource_web_url)
          Runtime::Logger.debug("Resource availability check for #{resource_web_url} ... #{response_check.code}")
          response_check.code == HTTP_STATUS_OK
        end
      end

      def extract_graphql_id(item)
        item.fetch(:id).split('/').last
      end

      def extract_graphql_resource(response, key)
        resource = response[key.to_sym]
        resource[:id] = extract_graphql_id(resource) if resource.key?(:id)
        resource
      end

      protected

      def post_success_response_code
        HTTP_STATUS_CREATED
      end
    end
  end
end
