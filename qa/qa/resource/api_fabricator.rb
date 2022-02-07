# frozen_string_literal: true

require 'active_support/core_ext/object/deep_dup'
require 'capybara/dsl'

module QA
  module Resource
    module ApiFabricator
      include Capybara::DSL
      include Support::API
      include Errors

      attr_writer :api_client
      attr_accessor :api_user, :api_resource, :api_response

      def api_support?
        respond_to?(:api_get_path) &&
          (respond_to?(:api_post_path) && respond_to?(:api_post_body)) ||
          (respond_to?(:api_put_path) && respond_to?(:api_put_body))
      end

      def fabricate_via_api!
        unless api_support?
          raise NotImplementedError, "Resource #{self.class.name} does not support fabrication via the API!"
        end

        resource_web_url(api_post)
      end

      def reload!
        api_get

        self
      end

      def remove_via_api!
        api_delete
      end

      def eager_load_api_client!
        return unless api_client.nil?

        api_client.tap do |client|
          # Eager-load the API client so that the personal token creation isn't
          # taken in account in the actual resource creation timing.
          client.user = user
          client.personal_access_token
        end
      end

      def api_put(body = api_put_body)
        response = put(
          Runtime::API::Request.new(api_client, api_put_path).url,
          body)

        unless response.code == HTTP_STATUS_OK
          raise ResourceFabricationFailedError, "Updating #{self.class.name} using the API failed (#{response.code}) with `#{response}`."
        end

        process_api_response(parse_body(response))
      end

      def api_fabrication_http_method
        @api_fabrication_http_method ||= :post
      end

      # Checks if a resource already exists
      #
      # @return [Boolean] true if the resource returns HTTP status code 200
      def exists?
        request = Runtime::API::Request.new(api_client, api_get_path)
        response = get(request.url)

        response.code == HTTP_STATUS_OK
      end

      private

      def resource_web_url(resource)
        resource.fetch(:web_url) do
          raise ResourceURLMissingError, "API resource for #{self.class.name} does not expose a `web_url` property: `#{resource}`."
        end
      end

      def api_get
        process_api_response(parse_body(api_get_from(api_get_path)))
      end

      def api_get_from(get_path)
        request = Runtime::API::Request.new(api_client, get_path)
        response = get(request.url)

        if response.code == HTTP_STATUS_SERVER_ERROR
          raise InternalServerError, "Failed to GET #{request.mask_url} - (#{response.code}): `#{response}`."
        elsif response.code != HTTP_STATUS_OK
          raise ResourceNotFoundError, "Resource at #{request.mask_url} could not be found (#{response.code}): `#{response}`."
        end

        @api_fabrication_http_method = :get # rubocop:disable Gitlab/ModuleWithInstanceVariables

        response
      end

      def api_post
        process_api_response(api_post_to(api_post_path, api_post_body))
      end

      def api_post_to(post_path, post_body)
        if post_path == "/graphql"
          graphql_response = post(Runtime::API::Request.new(api_client, post_path).url, query: post_body)

          body = flatten_hash(parse_body(graphql_response))

          unless graphql_response.code == HTTP_STATUS_OK && (body[:errors].nil? || body[:errors].empty?)
            raise(ResourceFabricationFailedError, <<~MSG)
              Fabrication of #{self.class.name} using the API failed (#{graphql_response.code}) with `#{graphql_response}`.
            MSG
          end

          body[:id] = body.fetch(:id).split('/').last

          body.transform_keys { |key| key.to_s.underscore.to_sym }
        else
          response = post(Runtime::API::Request.new(api_client, post_path).url, post_body)

          unless response.code == HTTP_STATUS_CREATED
            raise(
              ResourceFabricationFailedError,
              "Fabrication of #{self.class.name} using the API failed (#{response.code}) with `#{response}`."
            )
          end

          parse_body(response)
        end
      end

      def flatten_hash(param)
        param.each_pair.reduce({}) do |a, (k, v)|
          v.is_a?(Hash) ? a.merge(flatten_hash(v)) : a.merge(k.to_sym => v)
        end
      end

      def api_delete
        request = Runtime::API::Request.new(api_client, api_delete_path)
        response = delete(request.url)

        unless [HTTP_STATUS_NO_CONTENT, HTTP_STATUS_ACCEPTED].include? response.code
          raise ResourceNotDeletedError, "Resource at #{request.mask_url} could not be deleted (#{response.code}): `#{response}`."
        end

        response
      end

      def api_client
        @api_client ||= begin
          Runtime::API::Client.new(:gitlab, is_new_session: !current_url.start_with?('http'), user: api_user)
        end
      end

      def process_api_response(parsed_response)
        self.api_response = parsed_response
        self.api_resource = transform_api_resource(parsed_response.deep_dup)
      end

      def transform_api_resource(api_resource)
        api_resource
      end
    end
  end
end
