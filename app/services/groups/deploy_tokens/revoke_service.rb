# frozen_string_literal: true

module Groups
  module DeployTokens
    class RevokeService < BaseService
      attr_accessor :token, :source

      def execute
        @token = group.deploy_tokens.find(params[:id])
        @token.revoke!

        ServiceResponse.success(message: 'Token was revoked')
      end
    end
  end
end

Groups::DeployTokens::RevokeService.prepend_mod
