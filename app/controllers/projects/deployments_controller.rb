class Projects::DeploymentsController < Projects::ApplicationController
  layout 'project'

  def terminal
  end

  # GET /terminal_websocket : implemented in gitlab-workhorse

  def terminal_websocket_authorize
    Gitlab::Workhorse.verify_api_request!(request.headers)
    openshift_project = project.variables.find('CI_PROJECT_NAME').to_s
    openshift_app = project.variables.find('APP').to_s
    if openshift_project.present? && openshift_app.present?
      set_workhorse_internal_api_content_type
      render json: {openshift_app: openshift_app, openshift_project: openshift_project}
    else
      render text: 'Not found', status: 404
    end
  end
end
