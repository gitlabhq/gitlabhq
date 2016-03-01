module Ci
  class ProjectsController < Ci::ApplicationController
    before_action :project
    before_action :authorize_read_project!, except: [:badge]
    before_action :no_cache, only: [:badge]
    skip_before_action :authenticate_user!, only: [:badge]
    protect_from_forgery

    def show
      # Temporary compatibility with CI badges pointing to CI project page
      redirect_to namespace_project_path(project.namespace, project)
    end

    # Project status badge
    # Image with build status for sha or ref
    #
    # This action in DEPRECATED, this is here only for backwards compatibility
    # with projects migrated from GitLab CI.
    #
    def badge
      return render_404 unless @project

      image = Ci::ImageForBuildService.new.execute(@project, params)
      send_file image.path, filename: image.name, disposition: 'inline', type:"image/svg+xml"
    end

    protected

    def project
      @project ||= Project.find_by(ci_id: params[:id].to_i)
    end

    def no_cache
      response.headers["Cache-Control"] = "no-cache, no-store, max-age=0, must-revalidate"
      response.headers["Pragma"] = "no-cache"
      response.headers["Expires"] = "Fri, 01 Jan 1990 00:00:00 GMT"
    end
  end
end
