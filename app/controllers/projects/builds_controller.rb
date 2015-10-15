class Projects::BuildsController < Projects::ApplicationController
  before_action :ci_project
  before_action :build

  before_action :authorize_admin_project!, except: [:show, :status]

  layout "project"

  def show
    @builds = @ci_project.commits.find_by_sha(@build.sha).builds.order('id DESC')
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
      redirect_to build_path(build)
    end
  end

  def status
    render json: @build.to_json(only: [:status, :id, :sha, :coverage], methods: :sha)
  end

  def cancel
    @build.cancel

    redirect_to build_path(@build)
  end

  private

  def build
    @build ||= ci_project.builds.unscoped.find_by!(id: params[:id])
  end

  def build_path(build)
    namespace_project_build_path(build.gl_project.namespace, build.gl_project, build)
  end
end
