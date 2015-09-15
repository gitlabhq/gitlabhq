module Ci
  class RunnerProjectsController < Ci::ApplicationController
    before_action :authenticate_user!
    before_action :project
    before_action :authorize_manage_project!

    layout 'ci/project'

    def create
      @runner = Ci::Runner.find(params[:runner_project][:runner_id])

      return head(403) unless current_user.ci_authorized_runners.include?(@runner)

      if @runner.assign_to(project, current_user)
        redirect_to ci_project_runners_path(project)
      else
        redirect_to ci_project_runners_path(project), alert: 'Failed adding runner to project'
      end
    end

    def destroy
      runner_project = project.runner_projects.find(params[:id])
      runner_project.destroy

      redirect_to ci_project_runners_path(project)
    end

    private

    def project
      @project ||= Ci::Project.find(params[:project_id])
    end
  end
end
