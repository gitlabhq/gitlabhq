module Ci
  class CommitsController < Ci::ApplicationController
    before_action :authenticate_user!, except: [:status, :show]
    before_action :authenticate_public_page!, only: :show
    before_action :project
    before_action :authorize_access_project!, except: [:status, :show, :cancel]
    before_action :authorize_manage_builds!, only: [:cancel]
    before_action :commit, only: :show
    layout 'ci/commit'

    def show
      @builds = @commit.builds
    end

    def status
      commit = Ci::Project.find(params[:project_id]).commits.find_by_sha_and_ref!(params[:id], params[:ref_id])
      render json: commit.to_json(only: [:id, :sha], methods: [:status, :coverage])
    rescue ActiveRecord::RecordNotFound
      render json: { status: "not_found" }
    end

    def cancel
      commit.builds.running_or_pending.each(&:cancel)

      redirect_to ci_project_ref_commits_path(project, commit.ref, commit.sha)
    end

    private

    def project
      @project ||= Ci::Project.find(params[:project_id])
    end

    def commit
      @commit ||= Ci::Project.find(params[:project_id]).commits.find_by_sha_and_ref!(params[:id], params[:ref_id])
    end
  end
end
