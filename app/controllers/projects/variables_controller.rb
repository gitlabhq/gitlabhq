# frozen_string_literal: true

class Projects::VariablesController < Projects::ApplicationController
  before_action :authorize_admin_build!

  feature_category :pipeline_authoring

  def show
    respond_to do |format|
      format.json do
        render status: :ok, json: { variables: ::Ci::VariableSerializer.new.represent(@project.variables) }
      end
    end
  end

  def update
    update_result = Ci::ChangeVariablesService.new(
      container: @project, current_user: current_user,
      params: variables_params
    ).execute

    if update_result
      respond_to do |format|
        format.json { render_variables }
      end
    else
      respond_to do |format|
        format.json { render_error }
      end
    end
  end

  private

  def render_variables
    render status: :ok, json: { variables: ::Ci::VariableSerializer.new.represent(@project.variables) }
  end

  def render_error
    render status: :bad_request, json: @project.errors.full_messages
  end

  def variables_params
    params.permit(variables_attributes: [*variable_params_attributes])
  end

  def variable_params_attributes
    %i[id variable_type key secret_value protected masked environment_scope _destroy]
  end
end
