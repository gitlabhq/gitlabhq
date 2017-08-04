module EE
  module KubernetesService
    def rollout_status(environment)
      with_reactive_cache do |data|
        specs = filter_by_label(data[:deployments], app: environment.slug)

        ::Gitlab::Kubernetes::RolloutStatus.from_specs(*specs)
      end
    end

    def calculate_reactive_cache
      result = super
      result[:deployments] = read_deployments if result

      result
    end

    def read_deployments
      kubeclient = build_kubeclient!(api_path: 'apis/extensions', api_version: 'v1beta1')

      kubeclient.get_deployments(namespace: actual_namespace).as_json
    rescue KubeException => err
      raise err unless err.error_code == 404
      []
    end
  end
end
