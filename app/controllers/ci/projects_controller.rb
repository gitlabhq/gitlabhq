module Ci
  class ProjectsController < Ci::ApplicationController
    before_action :project, except: [:index]
    before_action :authenticate_user!, except: [:index, :build, :badge]
    before_action :authorize_access_project!, except: [:index, :badge]
    before_action :authorize_manage_project!, only: [:toggle_shared_runners, :dumped_yaml]
    before_action :no_cache, only: [:badge]
    protect_from_forgery

    def show
      # Temporary compatibility with CI badges pointing to CI project page
      redirect_to namespace_project_path(project.gl_project.namespace, project.gl_project)
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
