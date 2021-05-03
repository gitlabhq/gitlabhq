# frozen_string_literal: true

module API
  module Entities
    class Environment < Entities::EnvironmentBasic
      include RequestAwareEntity
      include Gitlab::Utils::StrongMemoize

      expose :project, using: Entities::BasicProjectDetails
      expose :last_deployment, using: Entities::Deployment, if: { last_deployment: true }
      expose :state

      expose :enable_advanced_logs_querying, if: -> (*) { can_read_pod_logs? } do |environment|
        environment.elastic_stack_available?
      end

      expose :logs_api_path, if: -> (*) { can_read_pod_logs? } do |environment|
        if environment.elastic_stack_available?
          elasticsearch_project_logs_path(environment.project, environment_name: environment.name, format: :json)
        else
          k8s_project_logs_path(environment.project, environment_name: environment.name, format: :json)
        end
      end

      expose :gitlab_managed_apps_logs_path, if: -> (*) { can_read_pod_logs? && cluster } do |environment|
        ::Clusters::ClusterPresenter.new(cluster, current_user: current_user).gitlab_managed_apps_logs_path # rubocop: disable CodeReuse/Presenter
      end

      private

      alias_method :environment, :object

      def can_read_pod_logs?
        strong_memoize(:can_read_pod_logs) do
          current_user&.can?(:read_pod_logs, environment.project)
        end
      end

      def cluster
        strong_memoize(:cluster) do
          environment&.last_deployment&.cluster
        end
      end

      def current_user
        options[:current_user]
      end
    end
  end
end
