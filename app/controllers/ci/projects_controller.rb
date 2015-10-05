module Ci
  class ProjectsController < Ci::ApplicationController
    before_action :authenticate_user!, except: [:build, :badge, :show]
    before_action :authenticate_public_page!, only: :show
    before_action :project, only: [:build, :show, :badge, :toggle_shared_runners, :dumped_yaml]
    before_action :authorize_access_project!, except: [:build, :badge, :show, :new]
    before_action :authorize_manage_project!, only: [:toggle_shared_runners, :dumped_yaml]
    before_action :authenticate_token!, only: [:build]
    before_action :no_cache, only: [:badge]
    protect_from_forgery except: :build

    layout 'ci/project', except: [:index]

    def show
      @ref = params[:ref]

      @commits = @project.commits.reverse_order
      # TODO: this is broken
      # @commits = @commits.where(ref: @ref) if @ref
      @commits = @commits.page(params[:page]).per(20)
    end

    # Project status badge
    # Image with build status for sha or ref
    def badge
      image = Ci::ImageForBuildService.new.execute(@project, params)

      send_file image.path, filename: image.name, disposition: 'inline', type:"image/svg+xml"
    end

    def toggle_shared_runners
      project.toggle!(:shared_runners_enabled)

      redirect_to namespace_project_runners_path(project.gl_project.namespace, project.gl_project)
    end

    def dumped_yaml
      send_data @project.generated_yaml_config, filename: '.gitlab-ci.yml'
    end

    protected

    def project
      @project ||= Ci::Project.find(params[:id])
    end

    def no_cache
      response.headers["Cache-Control"] = "no-cache, no-store, max-age=0, must-revalidate"
      response.headers["Pragma"] = "no-cache"
      response.headers["Expires"] = "Fri, 01 Jan 1990 00:00:00 GMT"
    end
  end
end
