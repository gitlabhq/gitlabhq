class Projects::VariablesController < Projects::ApplicationController
  prepend ::EE::Projects::VariablesController

  before_action :authorize_admin_build!

  layout 'project_settings'

  def index
    redirect_to project_settings_ci_cd_path(@project)
  end

  def show
    @variable = @project.variables.find(params[:id])
  end

  def update
    @variable = @project.variables.find(params[:id])

    if @variable.update_attributes(variable_params)
      redirect_to project_variables_path(project), notice: 'Variable was successfully updated.'
    else
      render action: "show"
    end
  end

  def create
    @variable = @project.variables.new(variable_params)

    if @variable.save
      flash[:notice] = 'Variables were successfully updated.'
      redirect_to project_settings_ci_cd_path(project)
    else
      render "show"
    end
  end

  def destroy
    @key = @project.variables.find(params[:id])
    @key.destroy

    redirect_to project_settings_ci_cd_path(project),
                status: 302,
                notice: 'Variable was successfully removed.'
  end

  private

  def variable_params
    params.require(:variable).permit(*variable_params_attributes)
  end

  def variable_params_attributes
    %i[id key value protected _destroy]
  end
end
