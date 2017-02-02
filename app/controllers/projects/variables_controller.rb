class Projects::VariablesController < Projects::ApplicationController
  before_action :authorize_admin_build!

  layout 'project_settings'

  def index
    redirect_to namespace_project_settings_ci_cd_path(@project.namespace, @project)
  end

  def show
    @variable = @project.variables.find(params[:id])
  end

  def update
    @variable = @project.variables.find(params[:id])

    if @variable.update_attributes(project_params)
      flash[:notice] = 'Variables were successfully updated.'
    else
      flash[:alert] = @variable.errors.full_messages.join(',').html_safe
    end
    redirect_to namespace_project_settings_ci_cd_path(project.namespace, project)
  end

  def create
    @variable = Ci::Variable.new(project_params)

    if @variable.valid? && @project.variables << @variable
      flash[:notice] = 'Variables were successfully updated.'
    else
      flash[:alert] = @variable.errors.full_messages.join(',').html_safe
    end
    redirect_to namespace_project_settings_ci_cd_path(project.namespace, project)
  end

  def destroy
    @key = @project.variables.find(params[:id])
    @key.destroy

    redirect_to namespace_project_settings_ci_cd_path(project.namespace, project), notice: 'Variable was successfully removed.'
  end

  private

  def project_params
    params.require(:variable).permit([:id, :key, :value, :_destroy])
  end
end
