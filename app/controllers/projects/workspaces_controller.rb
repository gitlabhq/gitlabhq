class Projects::WorkspacesController < Projects::ApplicationController
  before_action :authorize_read_environment!
  before_action :authorize_admin_environment!, only: :attach
  include Gitlab::Kubernetes

  def show
    environment = project.environments.find_or_create_by(name: 'development')
    kube = project.deployment_service if project.deployment_service

    unless kube.to_param == 'kubernetes' && kube.test[:success]
      render text: 'No kube', status: 500
      return
    end
    client = kube.send(:build_kubeclient!)
    # TODO: Check for existing cluster and spin up if needed via KubeClient

    pods = filter_by_label(client.get_pods(namespace: kube.actual_namespace).as_json, environment: 'dev-userid')

    unless pods.empty?
      render json: [ client.proxy_url('pod', 'dev-env', 9000, kube.actual_namespace), client.proxy_url('pod', 'dev-env', 5000, kube.actual_namespace) ]
    else
      pod = YAML.load_file(Rails.root.join('config/devenv-pod.yaml')).symbolize_keys
      client.create_pod(pod)
      render text: 'created'
    end
  end

  def attach
    Gitlab::Workhorse.verify_api_request!(request.headers)
    kube = project.deployment_service
    client = kube.send(:build_kubeclient!)
    pods = client.get_pods(namespace: kube.actual_namespace).as_json
    terminal = pods.flat_map { |pod| terminals_for_pod(kube.api_url, kube.actual_namespace, pod) }.last
    if terminal
      set_workhorse_internal_api_content_type
      render json: Gitlab::Workhorse.terminal_websocket(terminal)
    else
      render text: 'Not found', status: 404
    end
  end

end
