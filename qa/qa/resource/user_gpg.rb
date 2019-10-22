# frozen_string_literal: true

module QA
  module Resource
    class UserGPG < Base
      attr_accessor :id, :gpg
      attr_reader :key_id

      def initialize
        @gpg = Runtime::GPG.new
        @key_id = @gpg.key_id
      end

      def fabricate_via_api!
        super
        @id = self.api_response[:id]
      rescue ResourceFabricationFailedError => error
        if error.message.include? 'has already been taken'
          self
        else
          raise ResourceFabricationFailedError error
        end
      end

      def resource_web_url(resource)
        super
      rescue ResourceURLMissingError
        # this particular resource does not expose a web_url property
      end

      def api_get_path
        "/user/gpg_keys/#{@id}"
      end

      def api_post_path
        '/user/gpg_keys'
      end

      def api_post_body
        {
          key: @gpg.key
        }
      end
    end
  end
end
