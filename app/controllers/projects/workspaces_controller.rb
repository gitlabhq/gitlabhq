class Projects::WorkspacesController < Projects::ApplicationController
  before_action :authorize_read_environment!
  before_action :authorize_admin_environment!, only: :attach

  before_action :verify_kubernetes_service!

  include Gitlab::Kubernetes

  def show
    env = project.environments.find_or_create_by!(name: workspace_env)

    respond_to do |format|
      format.json { render json: project.deployment_service.development_proxy(env) }
      format.html
    end
  end

  def attach
    # Gitlab::Workhorse.verify_api_request!(request.headers)
    env = project.environments.find_by!(name: workspace_env)
    terminal = project.deployment_service.development_terminal(env)
    if terminal
      set_workhorse_internal_api_content_type
      render json: Gitlab::Workhorse.terminal_websocket(terminal)
    else
      render text: 'Not found', status: 404
    end
  end

  private

  def workspace_env
    "dev-#{current_user.id}"
  end

  def verify_kubernetes_service!
    unless project.deployment_service.to_param == 'kubernetes' && project.deployment_service.test
      render text: 'No kube', status: 500
    end
  end

end
