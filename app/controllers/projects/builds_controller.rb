class Projects::BuildsController < Projects::ApplicationController
  before_action :build, except: [:index, :cancel_all]
  before_action :authorize_read_build!, except: [:cancel, :cancel_all, :retry]
  before_action :authorize_update_build!, except: [:index, :show, :status]
  layout 'project'

  def index
    @scope = params[:scope]
    @all_builds = project.builds
    @builds = @all_builds.order('created_at DESC')
    @builds =
      case @scope
      when 'running'
        @builds.running_or_pending.reverse_order
      when 'finished'
        @builds.finished
      else
        @builds
      end
    @builds = @builds.page(params[:page]).per(30)
  end

  def commits
    @scope = params[:scope]
    @all_commits = project.ci_commits
    @commits = @all_commits.order(id: :desc)
    @commits =
      case @scope
      when 'latest'
        @commits
      when 'branches'
        refs = project.repository.branches.map(&:name)
        ids = @all_commits.where(ref: refs).group(:ref).select('max(id)')
        @commits.where(id: ids)
      when 'tags'
        refs = project.repository.tags.map(&:name)
        ids = @all_commits.where(ref: refs).group(:ref).select('max(id)')
        @commits.where(id: ids)
      else
        @commits
      end
    @commits = @commits.page(params[:page]).per(30)
  end

  private

  def cancel_all
    @project.builds.running_or_pending.each(&:cancel)
    redirect_to namespace_project_builds_path(project.namespace, project)
  end

  def show
    @builds = @project.ci_commits.find_by_sha(@build.sha).builds.order('id DESC')
    @builds = @builds.where("id not in (?)", @build.id)
    @commit = @build.commit

    respond_to do |format|
      format.html
      format.json do
        render json: @build.to_json(methods: :trace_html)
      end
    end
  end

  def retry
    unless @build.retryable?
      return render_404
    end

    build = Ci::Build.retry(@build)
    redirect_to build_path(build)
  end

  def cancel
    @build.cancel
    redirect_to build_path(@build)
  end

  def status
    render json: @build.to_json(only: [:status, :id, :sha, :coverage], methods: :sha)
  end

  def erase
    @build.erase(erased_by: current_user)
    redirect_to namespace_project_build_path(project.namespace, project, @build),
                notice: "Build has been sucessfully erased!"
  end

  private

  def build
    @build ||= project.builds.unscoped.find_by!(id: params[:id])
  end

  def ci_commit
    @ci_commit ||= project.ci_commits.find_by!(id: params[:id])
  end

  def build_path(build)
    namespace_project_build_path(build.project.namespace, build.project, build)
  end
end
