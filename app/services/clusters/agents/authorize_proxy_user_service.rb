# frozen_string_literal: true

module Clusters
  module Agents
    class AuthorizeProxyUserService < ::BaseService
      include ::Gitlab::Utils::StrongMemoize

      def initialize(current_user, agent)
        @current_user = current_user
        @agent = agent
      end

      def execute
        return forbidden('`user_access` keyword is not found in agent config file.') unless user_access_config.present?

        access_as = user_access_config['access_as']

        return forbidden('`access_as` is not found under the `user_access` keyword.') unless access_as.present?
        return forbidden('`access_as` must exist only once under the `user_access` keyword.') if access_as.size != 1

        handle_access(access_as)
      end

      private

      attr_reader :current_user, :agent

      # Override in EE
      def handle_access(access_as)
        access_as_agent if access_as.key?('agent')
      end

      def authorizations
        @authorizations ||= ::Clusters::Agents::Authorizations::UserAccess::Finder
          .new(current_user, agent: agent).execute
      end

      def response_base
        {
          agent: {
            id: agent.id,
            config_project: { id: agent.project_id }
          },
          user: {
            id: current_user.id,
            username: current_user.username
          }
        }
      end

      def access_as_agent
        if authorizations.empty?
          return forbidden('You must be a member of `projects` or `groups` under the `user_access` keyword.')
        end

        success(payload: response_base.merge(access_as: { agent: {} }))
      end

      def user_access_config
        agent.user_access_config
      end
      strong_memoize_attr :user_access_config

      delegate :success, to: ServiceResponse, private: true

      def forbidden(message)
        ServiceResponse.error(reason: :forbidden, message: message)
      end
    end
  end
end

Clusters::Agents::AuthorizeProxyUserService.prepend_mod
