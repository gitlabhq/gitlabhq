# frozen_string_literal: true

module Projects
  class LogsController < Projects::ApplicationController
    include ::Gitlab::Utils::StrongMemoize

    before_action :authorize_read_pod_logs!
    before_action :ensure_deployments, only: %i(k8s elasticsearch)

    feature_category :logging

    def index
      if environment || cluster
        render :index
      else
        render :empty_logs
      end
    end

    def k8s
      render_logs(::PodLogs::KubernetesService, k8s_params)
    end

    def elasticsearch
      render_logs(::PodLogs::ElasticsearchService, elasticsearch_params)
    end

    private

    def render_logs(service, permitted_params)
      ::Gitlab::UsageCounters::PodLogs.increment(project.id)
      ::Gitlab::PollingInterval.set_header(response, interval: 3_000)

      result = service.new(cluster, namespace, params: permitted_params).execute

      if result.nil?
        head :accepted
      elsif result[:status] == :success
        render json: result
      else
        render status: :bad_request, json: result
      end
    end

    # cluster is selected either via environment or directly by id
    def cluster_params
      params.permit(:environment_name, :cluster_id)
    end

    def k8s_params
      params.permit(:container_name, :pod_name)
    end

    def elasticsearch_params
      params.permit(:container_name, :pod_name, :search, :start_time, :end_time, :cursor)
    end

    def environment
      strong_memoize(:environment) do
        if cluster_params.key?(:environment_name)
          ::Environments::EnvironmentsFinder.new(project, current_user, name: cluster_params[:environment_name]).execute.first
        else
          project.default_environment
        end
      end
    end

    def cluster
      strong_memoize(:cluster) do
        if gitlab_managed_apps_logs?
          clusters = ClusterAncestorsFinder.new(project, current_user).execute
          clusters.find { |cluster| cluster.id == cluster_params[:cluster_id].to_i }
        else
          environment&.deployment_platform&.cluster
        end
      end
    end

    def namespace
      if gitlab_managed_apps_logs?
        Gitlab::Kubernetes::Helm::NAMESPACE
      else
        environment.deployment_namespace
      end
    end

    def ensure_deployments
      return if gitlab_managed_apps_logs?
      return if cluster && namespace.present?

      render status: :bad_request, json: {
        status: :error,
        message: _('Environment does not have deployments')
      }
    end

    def gitlab_managed_apps_logs?
      cluster_params.key?(:cluster_id)
    end
  end
end
