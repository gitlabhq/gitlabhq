module Ci
  class VariablesController < Ci::ApplicationController
    before_action :authenticate_user!
    before_action :project
    before_action :authorize_access_project!
    before_action :authorize_manage_project!

    layout 'ci/project'

    def show
    end

    def update
      if project.update_attributes(project_params)
        Ci::EventService.new.change_project_settings(current_user, project)

        redirect_to ci_project_variables_path(project), notice: 'Variables were successfully updated.'
      else
        render action: 'show'
      end
    end

    private

    def project
      @project ||= Ci::Project.find(params[:project_id])
    end

    def project_params
      params.require(:project).permit({ variables_attributes: [:id, :key, :value, :_destroy] })
    end
  end
end
