# frozen_string_literal: true

module Projects
  module DeployTokens
    class RevokeService < BaseProjectService
      attr_accessor :token, :source

      def execute
        return ServiceResponse.error(message: 'Unauthorized to revoke project deploy token') unless can_revoke_token?

        @token = project.deploy_tokens.find(params[:id])

        token.revoke!

        ServiceResponse.success(message: 'Token was revoked')
      rescue ActiveRecord::RecordNotFound, ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved
        ServiceResponse.error(message: 'Token was not revoked')
      end

      private

      def can_revoke_token?
        current_user.can_admin_all_resources?
      end
    end
  end
end
