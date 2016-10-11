class Projects::DeploymentsController < Projects::ApplicationController
  layout 'project'

  def terminal
  end

  # GET /terminal_websocket : implemented in gitlab-workhorse

  def terminal_websocket_authorize
    Gitlab::Workhorse.verify_api_request!(request.headers)
    openshift_project = project.variables.find_by(key: 'CI_PROJECT_NAME')
    openshift_app = project.variables.find_by(key: 'APP')
    # TODO: restrict access: this allows even 'guests' to have terminal access
    if openshift_project.present? && openshift_app.present?
      set_workhorse_internal_api_content_type
      render json: {openshift_app: openshift_app.value, openshift_project: openshift_project.value}
    else
      render text: 'Not found', status: 404
    end
  end
end
