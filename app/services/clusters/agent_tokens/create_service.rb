# frozen_string_literal: true

module Clusters
  module AgentTokens
    class CreateService < ::BaseContainerService
      ALLOWED_PARAMS = %i[agent_id description name].freeze

      def execute
        return error_no_permissions unless current_user.can?(:create_cluster, container)

        token = ::Clusters::AgentToken.new(filtered_params.merge(created_by_user: current_user))

        if token.save
          log_activity_event!(token)

          ServiceResponse.success(payload: { secret: token.token, token: token })
        else
          ServiceResponse.error(message: token.errors.full_messages)
        end
      end

      private

      def error_no_permissions
        ServiceResponse.error(message: s_('ClusterAgent|User has insufficient permissions to create a token for this project'))
      end

      def filtered_params
        params.slice(*ALLOWED_PARAMS)
      end

      def log_activity_event!(token)
        Clusters::Agents::CreateActivityEventService.new(
          token.agent,
          kind: :token_created,
          level: :info,
          recorded_at: token.created_at,
          user: current_user,
          agent_token: token
        ).execute
      end
    end
  end
end
