class Projects::VariablesController < Projects::ApplicationController
  before_action :authorize_admin_build!

  layout 'project_settings'

  def show
  end

  def update
    if project.update_attributes(project_params)
      redirect_to namespace_project_variables_path(project.namespace, project), notice: 'Variables were successfully updated.'
    else
      render action: 'show'
    end
  end

  private

  def project_params
    params.require(:project).permit({ variables_attributes: [:id, :key, :value, :_destroy] })
  end
end
