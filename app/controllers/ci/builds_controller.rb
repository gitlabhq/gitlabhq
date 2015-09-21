module Ci
  class BuildsController < Ci::ApplicationController
    before_action :authenticate_user!, except: [:status, :show]
    before_action :authenticate_public_page!, only: :show
    before_action :project
    before_action :authorize_access_project!, except: [:status, :show]
    before_action :authorize_manage_project!, except: [:status, :show, :retry, :cancel]
    before_action :authorize_manage_builds!, only: [:retry, :cancel]
    before_action :build, except: [:show]
    layout 'ci/build'

    def show
      if params[:id] =~ /\A\d+\Z/
        @build = build
      else
        # try to find commit by sha
        commit = commit_by_sha

        if commit
          # Redirect to commit page
          redirect_to ci_project_ref_commit_path(@project, @build.commit.ref, @build.commit.sha)
          return
        end
      end

      raise ActiveRecord::RecordNotFound unless @build

      @builds = @project.commits.find_by_sha(@build.sha).builds.order('id DESC')
      @builds = @builds.where("id not in (?)", @build.id).page(params[:page]).per(20)
      @commit = @build.commit

      respond_to do |format|
        format.html
        format.json do
          render json: @build.to_json(methods: :trace_html)
        end
      end
    end

    def retry
      if @build.commands.blank?
        return page_404
      end

      build = Ci::Build.retry(@build)

      if params[:return_to]
        redirect_to URI.parse(params[:return_to]).path
      else
        redirect_to ci_project_build_path(project, build)
      end
    end

    def status
      render json: @build.to_json(only: [:status, :id, :sha, :coverage], methods: :sha)
    end

    def cancel
      @build.cancel

      redirect_to ci_project_build_path(@project, @build)
    end

    protected

    def project
      @project = Ci::Project.find(params[:project_id])
    end

    def build
      @build ||= project.builds.unscoped.find_by(id: params[:id])
    end

    def commit_by_sha
      @project.commits.find_by(sha: params[:id])
    end
  end
end
