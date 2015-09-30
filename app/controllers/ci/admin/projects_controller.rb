module Ci
  class Admin::ProjectsController < Ci::Admin::ApplicationController
    def index
      @projects = Ci::Project.ordered_by_last_commit_date.page(params[:page]).per(30)
    end

    def destroy
      project.destroy

      redirect_to ci_projects_url
    end

    protected

    def project
      @project ||= Ci::Project.find(params[:id])
    end
  end
end
