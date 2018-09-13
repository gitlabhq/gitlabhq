require 'airborne'

module QA
  module Factory
    module ApiFabricator
      include Airborne

      ResourceNotFoundError = Class.new(RuntimeError)
      ResourceFabricationFailedError = Class.new(RuntimeError)
      ResourceURLMissingError = Class.new(RuntimeError)

      attr_reader :api_resource

      def api_get_path
        raise NotImplementedError, "Factory #{self.class.name} does not support fabrication via the API!"
      end

      alias_method :api_post_path, :api_get_path
      alias_method :api_post_body, :api_get_path

      def api_support?
        api_get_path && api_post_path && api_post_body
      rescue NotImplementedError
        false
      end

      def fabricate_via_api!(*_args)
        resource_web_url(api_get)
      rescue ResourceNotFoundError
        resource_web_url(api_post)
      end

      private

      def resource_web_url(resource)
        unless resource.key?(:web_url)
          raise ResourceURLMissingError, "API resource for #{self.class.name} does not expose a `web_url` property: `#{resource}`."
        end

        resource[:web_url]
      end

      def api_get
        url = Runtime::API::Request.new(api_client, api_get_path).url
        response = get(url)
        resource = parse_body(response)

        unless response.code == 200
          raise ResourceNotFoundError, "Resource at #{url} could not be found (#{response.code}): `#{resource}`."
        end

        store_resource(resource)
      end

      def api_post
        response = post(
          Runtime::API::Request.new(api_client, api_post_path).url,
          api_post_body)
        resource = parse_body(response)

        unless response.code == 201
          raise ResourceFabricationFailedError, "Fabrication of #{self.class.name} using the API failed (#{response.code}) with `#{resource}`."
        end

        store_resource(resource)
      end

      def api_client
        @api_client ||= Runtime::API::Client.new(:gitlab, is_new_session: false)
      end

      def parse_body(response)
        JSON.parse(response.body, symbolize_names: true)
      end

      def store_resource(resource)
        @api_resource ||= resource
      end
    end
  end
end
