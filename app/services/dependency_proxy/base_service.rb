# frozen_string_literal: true

module DependencyProxy
  class BaseService < ::BaseService
    class DownloadError < StandardError
      attr_reader :http_status

      def initialize(message, http_status)
        @http_status = http_status

        super(message)
      end
    end

    private

    def registry
      DependencyProxy::Registry
    end

    def auth_headers
      {
        Authorization: "Bearer #{@token}"
      }
    end
  end
end
