class Projects::VariablesController < Projects::ApplicationController
  before_action :variable, only: [:show, :update, :destroy]
  before_action :authorize_admin_build!

  layout 'project_settings'

  def index
    redirect_to namespace_project_settings_ci_cd_path(@project.namespace, @project)
  end

  def show
  end

  def update
    if @variable.update(project_params)
      redirect_to project_variables_path(project),
                  notice: 'Variable was successfully updated.'
    else
      render "show"
    end
  end

  def create
    new_variable = project.variables.create(project_params)

    if new_variable.persisted?
      redirect_to project_settings_ci_cd_path(project),
                  notice: 'Variables were successfully updated.'
    else
      @variable = new_variable.present(current_user: current_user)
      render "show"
    end
  end

  def destroy
    if variable.destroy
      redirect_to namespace_project_settings_ci_cd_path(project.namespace, project),
                  status: 302,
                  notice: 'Variable was successfully removed.'
    else
      redirect_to namespace_project_settings_ci_cd_path(project.namespace, project),
                  status: 302,
                  notice: 'Failed to remove the variable'
    end
  end

  private

  def project_params
    params.require(:variable).permit([:id, :key, :value, :protected, :_destroy])
  end

  def variable
    @variable ||= project.variables.find(params[:id]).present(current_user: current_user)
  end
end
