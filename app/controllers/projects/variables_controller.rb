class Projects::VariablesController < Projects::ApplicationController
  prepend ::EE::Projects::VariablesController

  before_action :authorize_admin_build!

  def save_multiple
    respond_to do |format|
      format.json do
        return head :ok if @project.update(variables_params)

        head :bad_request
      end
    end
  end

  private

  def variables_params
    params.permit(variables_attributes: [*variable_params_attributes])
  end

  def variable_params_attributes
    %i[id key value protected _destroy]
  end
end
