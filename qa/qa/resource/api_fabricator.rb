# frozen_string_literal: true

require 'active_support/core_ext/object/deep_dup'
require 'capybara/dsl'

module QA
  module Resource
    module ApiFabricator
      include Capybara::DSL

      ResourceNotFoundError = Class.new(RuntimeError)
      ResourceFabricationFailedError = Class.new(RuntimeError)
      ResourceURLMissingError = Class.new(RuntimeError)
      ResourceNotDeletedError = Class.new(RuntimeError)

      attr_reader :api_resource, :api_response
      attr_writer :api_client
      attr_accessor :user

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

      private

      include Support::Api
      attr_writer :api_resource, :api_response

      def resource_web_url(resource)
        resource.fetch(:web_url) do
          raise ResourceURLMissingError, "API resource for #{self.class.name} does not expose a `web_url` property: `#{resource}`."
        end
      end

      def api_get
        process_api_response(parse_body(api_get_from(api_get_path)))
      end

      def api_get_from(get_path)
        url = Runtime::API::Request.new(api_client, get_path).url
        response = get(url)

        unless response.code == HTTP_STATUS_OK
          raise ResourceNotFoundError, "Resource at #{url} could not be found (#{response.code}): `#{response}`."
        end

        response
      end

      def api_post
        response = post(
          Runtime::API::Request.new(api_client, api_post_path).url,
          api_post_body)

        unless response.code == HTTP_STATUS_CREATED
          raise ResourceFabricationFailedError, "Fabrication of #{self.class.name} using the API failed (#{response.code}) with `#{response}`."
        end

        process_api_response(parse_body(response))
      end

      def api_put
        response = put(
          Runtime::API::Request.new(api_client, api_put_path).url,
          api_put_body)

        unless response.code == HTTP_STATUS_OK
          raise ResourceFabricationFailedError, "Updating #{self.class.name} using the API failed (#{response.code}) with `#{response}`."
        end

        process_api_response(parse_body(response))
      end

      def api_delete
        url = Runtime::API::Request.new(api_client, api_delete_path).url
        response = delete(url)

        unless [HTTP_STATUS_NO_CONTENT, HTTP_STATUS_ACCEPTED].include? response.code
          raise ResourceNotDeletedError, "Resource at #{url} could not be deleted (#{response.code}): `#{response}`."
        end

        response
      end

      def api_client
        @api_client ||= begin
          Runtime::API::Client.new(:gitlab, is_new_session: !current_url.start_with?('http'), user: user)
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
