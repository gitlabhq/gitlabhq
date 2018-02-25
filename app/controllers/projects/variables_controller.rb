class Projects::VariablesController < Projects::ApplicationController
  before_action :authorize_admin_build!

  def show
    respond_to do |format|
      format.json do
        render status: :ok, json: { variables: VariableSerializer.new.represent(@project.variables) }
      end
    end
  end

  def update
    if @project.update(filtered_variables_params)
      respond_to do |format|
        format.json { return render_variables }
      end
    else
      respond_to do |format|
        format.json { render_error }
      end
    end
  end

  private

  def render_variables
    render status: :ok, json: { variables: VariableSerializer.new.represent(@project.variables) }
  end

  def render_error
    render status: :bad_request, json: @project.errors.full_messages
  end

  def variables_params
    params.permit(variables_attributes: [*variable_params_attributes])
  end

  def filtered_variables_params
    params = variables_params
    params['variables_attributes'].group_by { |var| var['key'] }.each_value do |variables|
      if variables.count > 1
        variable = variables.find { |var| var['_destroy'] == 'true' }
        next unless variable

        params['variables_attributes'].delete(variable)
        params['variables_attributes'].find { |var| var['key'] == variable['key'] }['id'] = variable['id']
      end
    end
    params
  end

  def variable_params_attributes
    %i[id key value protected _destroy]
  end
end
