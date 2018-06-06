module EE
  module KubernetesService
    extend ActiveSupport::Concern

    LOGS_LIMIT = 500.freeze

    def rollout_status(environment)
      result = with_reactive_cache do |data|
        deployments = filter_by_label(data[:deployments], app: environment.slug)
        pods = filter_by_label(data[:pods], app: environment.slug) if data[:pods]&.any?

        ::Gitlab::Kubernetes::RolloutStatus.from_deployments(*deployments, pods: pods)
      end
      result || ::Gitlab::Kubernetes::RolloutStatus.loading
    end

    def calculate_reactive_cache
      result = super
      result[:deployments] = read_deployments if result

      result
    end

    def reactive_cache_updated
      super

      ::Gitlab::EtagCaching::Store.new.tap do |store|
        store.touch(
          ::Gitlab::Routing.url_helpers.project_environments_path(project, format: :json))
      end
    end

    def read_deployments
      kubeclient = build_kubeclient!(api_path: 'apis/extensions', api_version: 'v1beta1')

      kubeclient.get_deployments(namespace: actual_namespace).as_json
    rescue KubeException => err
      raise err unless err.error_code == 404

      []
    end

    def read_pod_logs(pod_name, container: nil)
      kubeclient.get_pod_log(pod_name, actual_namespace, container: container, tail_lines: LOGS_LIMIT).as_json
    rescue ::Kubeclient::HttpError => err
      raise err unless err.error_code == 404

      []
    end
  end
end
