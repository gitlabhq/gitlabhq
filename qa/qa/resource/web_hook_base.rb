# frozen_string_literal: true

module QA
  module Resource
    class WebHookBase < Base
      attributes :id, :url

      attribute :token do
        nil
      end

      attribute :enable_ssl_verification do
        false
      end

      def fabricate_via_api!
        resource_web_url = super

        @id = api_response[:id]

        resource_web_url
      end

      # @return [String] the api path to fetch the resource
      def api_get_path
        raise NotImplementedError, not_implemented_message(__callee__)
      end

      # @return [String] the api path to create the resource
      def api_post_path
        raise NotImplementedError, not_implemented_message(__callee__)
      end

      # @return [Hash] the payload needed to create the resource
      def api_post_body
        raise NotImplementedError, not_implemented_message(__callee__)
      end

      private

      def not_implemented_message(callee)
        "#{self.class} must implement ##{callee}"
      end
    end
  end
end
