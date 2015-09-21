module Ci
  class Admin::RunnerProjectsController < Ci::Admin::ApplicationController
    layout 'ci/project'

    def index
      @runner_projects = project.runner_projects.all
      @runner_project = project.runner_projects.new
    end

    def create
      @runner = Ci::Runner.find(params[:runner_project][:runner_id])

      if @runner.assign_to(project, current_user)
        redirect_to ci_admin_runner_path(@runner)
      else
        redirect_to ci_admin_runner_path(@runner), alert: 'Failed adding runner to project'
      end
    end

    def destroy
      rp = Ci::RunnerProject.find(params[:id])
      runner = rp.runner
      rp.destroy

      redirect_to ci_admin_runner_path(runner)
    end

    private

    def project
      @project ||= Ci::Project.find(params[:project_id])
    end
  end
end
