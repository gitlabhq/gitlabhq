# frozen_string_literal: true

module QA
  module Resource
    class GroupCiVariable < Base
      attr_accessor :key, :value, :masked, :protected

      attribute :group do
        QA::Resource::Group.fabricate_via_api!
      end

      def initialize
        @masked = false
        @protected = false
      end

      def fabricate_via_api!
        resource_web_url(api_get)
      rescue ResourceNotFoundError
        super
      end

      def resource_web_url(resource)
        super
      rescue ResourceURLMissingError
        # this particular resource does not expose a web_url property
      end

      def api_get_path
        "/groups/#{group.id}/variables/#{key}"
      end

      def api_post_path
        "/groups/#{group.id}/variables"
      end

      def api_post_body
        {
          key: key,
          value: value,
          masked: masked,
          protected: protected
        }
      end
    end
  end
end
