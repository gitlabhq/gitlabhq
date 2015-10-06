module Ci
  class CommitsController < Ci::ApplicationController
    before_action :authenticate_user!, except: [:status, :show]
    before_action :authenticate_public_page!, only: :show
    before_action :project
    before_action :authorize_access_project!, except: [:status, :show, :cancel]
    before_action :authorize_manage_builds!, only: [:cancel]

    def status
      commit = Ci::Project.find(params[:project_id]).commits.find_by_sha!(params[:id])
      render json: commit.to_json(only: [:id, :sha], methods: [:status, :coverage])
    rescue ActiveRecord::RecordNotFound
      render json: { status: "not_found" }
    end

    def cancel
      commit.builds.running_or_pending.each(&:cancel)

      redirect_to namespace_project_commit_path(commit.gl_project.namespace, commit.gl_project, commit.sha)
    end

    private

    def project
      @project ||= Ci::Project.find(params[:project_id])
    end

    def commit
      @commit ||= Ci::Project.find(params[:project_id]).commits.find_by_sha!(params[:id])
    end
  end
end
