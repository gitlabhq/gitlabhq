# frozen_string_literal: true

module Clusters
  module AgentTokens
    class CreateService
      ALLOWED_PARAMS = %i[agent_id description name].freeze
      ACTIVE_TOKENS_LIMIT = 2

      attr_reader :agent, :current_user, :params

      def initialize(agent:, current_user:, params:)
        @agent = agent
        @current_user = current_user
        @params = params
      end

      def execute
        return error_no_permissions unless current_user.can?(:create_cluster, agent.project)
        return error_active_tokens_limit_reached if active_tokens_limit_reached?

        token = ::Clusters::AgentToken.new(filtered_params.merge(agent_id: agent.id, created_by_user: current_user))

        if token.save
          log_activity_event(token)

          ServiceResponse.success(payload: { secret: token.token, token: token })
        else
          ServiceResponse.error(message: token.errors.full_messages)
        end
      end

      private

      def error_no_permissions
        ServiceResponse.error(message: s_('ClusterAgent|User has insufficient permissions to create a token for this project'))
      end

      def error_active_tokens_limit_reached
        ServiceResponse.error(message: s_('ClusterAgent|An agent can have only two active tokens at a time'))
      end

      def active_tokens_limit_reached?
        ::Clusters::AgentTokensFinder.new(agent, current_user, status: :active).execute.count >= ACTIVE_TOKENS_LIMIT
      end

      def filtered_params
        params.slice(*ALLOWED_PARAMS)
      end

      def log_activity_event(token)
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

Clusters::AgentTokens::CreateService.prepend_mod
