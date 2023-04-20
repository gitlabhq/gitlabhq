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
        return forbidden unless user_access_config.present?

        access_as = user_access_config[:access_as]
        return forbidden unless access_as.present?
        return forbidden if access_as.size != 1

        if authorizations = handle_access(access_as, user_access_config)
          return success(payload: authorizations)
        end

        forbidden
      end

      private

      attr_reader :current_user, :agent

      # Override in EE
      def handle_access(access_as, user_access)
        access_as_agent(user_access) if access_as.key?(:agent)
      end

      def response_base
        {
          agent: {
            id: agent.id,
            config_project: { id: agent.project.id }
          },
          user: {
            id: current_user.id,
            username: current_user.username
          }
        }
      end

      def access_as_agent(user_access)
        projects = authorized_projects(user_access)
        groups = authorized_groups(user_access)
        return unless projects.size + groups.size > 0

        response_base.merge(access_as: { agent: {} })
      end

      def authorized_projects(user_access)
        strong_memoize_with(:authorized_projects, user_access) do
          user_access.fetch(:projects, [])
            .first(::Clusters::Agents::Authorizations::CiAccess::RefreshService::AUTHORIZED_ENTITY_LIMIT)
            .map { |project| ::Project.find_by_full_path(project[:id]) }
            .select { |project| current_user.can?(:use_k8s_proxies, project) }
        end
      end

      def authorized_groups(user_access)
        strong_memoize_with(:authorized_groups, user_access) do
          user_access.fetch(:groups, [])
            .first(::Clusters::Agents::Authorizations::CiAccess::RefreshService::AUTHORIZED_ENTITY_LIMIT)
            .map { |group| ::Group.find_by_full_path(group[:id]) }
            .select { |group| current_user.can?(:use_k8s_proxies, group) }
        end
      end

      def user_access_config
        # TODO: Read the configuration from the database once it has been
        #       indexed. See https://gitlab.com/gitlab-org/gitlab/-/issues/389430
        branch = agent.project.default_branch_or_main
        path = ".gitlab/agents/#{agent.name}/config.yaml"
        config_yaml = agent.project.repository
                        &.blob_at_branch(branch, path)
                        &.data
        return unless config_yaml.present?

        config = YAML.safe_load(config_yaml, aliases: true, symbolize_names: true)
        config[:user_access]
      end
      strong_memoize_attr :user_access_config

      delegate :success, to: ServiceResponse, private: true

      def forbidden
        ServiceResponse.error(reason: :forbidden, message: '403 Forbidden')
      end
    end
  end
end

Clusters::Agents::AuthorizeProxyUserService.prepend_mod
