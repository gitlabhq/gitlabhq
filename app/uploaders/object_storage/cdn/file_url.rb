# frozen_string_literal: true

module ObjectStorage
  module CDN
    class FileUrl
      def initialize(file:, ip_address:, redirect_params: {})
        @file = file
        @ip_address = ip_address
        @redirect_params = redirect_params
      end

      def url
        if file.respond_to?(:cdn_enabled_url)
          result = file.cdn_enabled_url(ip_address, redirect_params[:query])
          Gitlab::ApplicationContext.push(artifact_used_cdn: result.used_cdn)
          result.url
        else
          file.url(**redirect_params)
        end
      end

      private

      attr_reader :file, :ip_address, :redirect_params
    end
  end
end
