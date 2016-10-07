class Projects::DeploymentsController < Projects::ApplicationController
  layout 'project'

  def terminal
  end

  # GET /terminal_websocket : implemented in gitlab-workhorse

  def terminal_websocket_authorize
    Gitlab::Workhorse.verify_api_request!(request.headers)
    if true # extra access checks, config flags can go here
      set_workhorse_internal_api_content_type
      render json: {} # Kubernetes namespace/pod/container should go here
    else
      render text: 'Not found', status: 404
    end
  end
end
