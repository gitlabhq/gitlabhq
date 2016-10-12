class Projects::DeploymentsController < Projects::ApplicationController
  layout 'project'

  before_action :deployment

  def terminal
  end

  # GET /terminal_websocket : implemented in gitlab-workhorse

  def terminal_websocket_authorize
    Gitlab::Workhorse.verify_api_request!(request.headers)

    render text: 'Missing deployable', status: 404 unless deployment.deployable

    deployable_variables = deployment.deployable.variables

    variables = Hash[*%w[
      openshift_project CI_PROJECT_NAME
      openshift_app APP
      openshift_server OPENSHIFT_SERVER
      openshift_token OPENSHIFT_TOKEN
    ]].map do |json_key, variable_key|
      [json_key, deployable_variables.find { |v| v[:key].to_s == variable_key }]
    end.to_h

    # TODO: restrict access: this allows even 'guests' to have terminal access
    if variables.values.all?(&:present?)
      set_workhorse_internal_api_content_type
      render json: variables.map { |k, v| [k, ExpandVariables.expand(v[:value], deployable_variables)] }.to_h
    else
      render json: { message: 'Not found', variables: variables, deployable_variables: deployable_variables }, status: 404
    end
  end

  protected

  def deployment
    @deployment ||= project.deployments.find_by(iid: params[:id].to_i)
    @deployment || render_404
  end
end
