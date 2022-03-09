# frozen_string_literal: true

module Groups
  module DeployTokens
    class RevokeService < BaseService
      attr_accessor :token

      def execute
        @token = group.deploy_tokens.find(params[:id])
        @token.revoke!
      end
    end
  end
end

Groups::DeployTokens::RevokeService.prepend_mod
