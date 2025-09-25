# frozen_string_literal: true

# rubocop:disable Mcp/UseApiService -- Tool does not depend on REST API
module Mcp
  module Tools
    class CustomService < BaseService
      extend Gitlab::Utils::Override

      override :set_cred
      def set_cred(current_user: nil, access_token: nil)
        @current_user = current_user
        _ = access_token # access_token is not used in CustomService
      end

      def execute(request: nil, params: nil)
        if current_user.present?
          super
        else
          Response.error("CustomService: current_user is not set")
        end
      end
    end
  end
end
# rubocop:enable Mcp/UseApiService
