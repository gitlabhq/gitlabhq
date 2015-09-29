class Projects::VariablesController < Projects::ApplicationController
  before_action :ci_project
  before_action :authorize_admin_project!

  layout 'project_settings'

  def show
  end

  def update
    if ci_project.update_attributes(project_params)
      Ci::EventService.new.change_project_settings(current_user, ci_project)

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
