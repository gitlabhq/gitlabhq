# frozen_string_literal: true

module Clusters
  module AgentTokens
    class RevokeService
      attr_reader :current_project, :current_user, :token

      def initialize(token:, current_user:)
        @token = token
        @current_user = current_user
      end

      def execute
        return error_no_permissions unless current_user.can?(:create_cluster, token.agent.project)

        if token.update(status: token.class.statuses[:revoked])
          ServiceResponse.success
        else
          ServiceResponse.error(message: token.errors.full_messages)
        end
      end

      private

      def error_no_permissions
        ServiceResponse.error(
          message: s_('ClusterAgent|User has insufficient permissions to revoke the token for this project'))
      end
    end
  end
end

Clusters::AgentTokens::RevokeService.prepend_mod
