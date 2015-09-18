module Ci
  class ProjectsController < Ci::ApplicationController
    PROJECTS_BATCH = 100

    before_action :authenticate_user!, except: [:build, :badge, :index, :show]
    before_action :authenticate_public_page!, only: :show
    before_action :project, only: [:build, :integration, :show, :badge, :edit, :update, :destroy, :toggle_shared_runners, :dumped_yaml]
    before_action :authorize_access_project!, except: [:build, :badge, :index, :show, :new, :create, :disabled]
    before_action :authorize_manage_project!, only: [:edit, :integration, :update, :destroy, :toggle_shared_runners, :dumped_yaml]
    before_action :authenticate_token!, only: [:build]
    before_action :no_cache, only: [:badge]
    skip_before_action :check_enable_flag!, only: [:disabled]
    protect_from_forgery except: :build

    layout 'ci/project', except: [:index, :disabled]

    def disabled
    end

    def index
      @limit, @offset = (params[:limit] || PROJECTS_BATCH).to_i, (params[:offset] || 0).to_i
      @page = @offset == 0 ? 1 : (@offset / @limit + 1)

      if current_user
        @projects = ProjectListBuilder.new.execute(current_user, params[:search])

        @projects = @projects.page(@page).per(@limit)

        @total_count = @projects.size
      end

      respond_to do |format|
        format.json do
          pager_json("ci/projects/index", @total_count)
        end
        format.html
      end
    end

    def show
      @ref = params[:ref]

      @commits = @project.commits.reverse_order
      @commits = @commits.where(ref: @ref) if @ref
      @commits = @commits.page(params[:page]).per(20)
    end

    def integration
    end

    def create
      project_data = OpenStruct.new(JSON.parse(params["project"]))

      unless can?(current_user, :admin_project, ::Project.find(project_data.id))
        return redirect_to ci_root_path, alert: 'You have to have at least master role to enable CI for this project'
      end

      @project = Ci::CreateProjectService.new.execute(current_user, project_data)

      if @project.persisted?
        redirect_to ci_project_path(@project, show_guide: true), notice: 'Project was successfully created.'
      else
        redirect_to :back, alert: 'Cannot save project'
      end
    end

    def edit
    end

    def update
      if project.update_attributes(project_params)
        Ci::EventService.new.change_project_settings(current_user, project)

        redirect_to :back, notice: 'Project was successfully updated.'
      else
        render action: "edit"
      end
    end

    def destroy
      project.gl_project.gitlab_ci_service.update_attributes(active: false)
      project.destroy

      Ci::EventService.new.remove_project(current_user, project)

      redirect_to ci_projects_url
    end

    # Project status badge
    # Image with build status for sha or ref
    def badge
      image = Ci::ImageForBuildService.new.execute(@project, params)

      send_file image.path, filename: image.name, disposition: 'inline', type:"image/svg+xml"
    end

    def toggle_shared_runners
      project.toggle!(:shared_runners_enabled)
      redirect_to :back
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

    def project_params
      params.require(:project).permit(:path, :timeout, :timeout_in_minutes, :default_ref, :always_build,
        :polling_interval, :public, :ssh_url_to_repo, :allow_git_fetch, :email_recipients,
        :email_add_pusher, :email_only_broken_builds, :coverage_regex, :shared_runners_enabled, :token,
        { variables_attributes: [:id, :key, :value, :_destroy] })
    end
  end
end
