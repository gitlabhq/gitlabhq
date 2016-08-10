class Projects::BuildsController < Projects::ApplicationController
  before_action :build, except: [:index, :cancel_all]
  before_action :authorize_read_build!, except: [:cancel, :cancel_all, :retry, :play]
  before_action :authorize_update_build!, except: [:index, :show, :status, :raw]
  layout 'project'

  def index
    @scope = params[:scope]
    @all_builds = project.builds.relevant
    @builds = @all_builds.order('created_at DESC')
    @builds =
      case @scope
      when 'pending'
        @builds.pending.reverse_order
      when 'running'
        @builds.running.reverse_order
      when 'finished'
        @builds.finished
      else
        @builds
      end
    @builds = @builds.page(params[:page]).per(30)
  end

  def cancel_all
    @project.builds.running_or_pending.each(&:cancel)
    redirect_to namespace_project_builds_path(project.namespace, project)
  end

  def show
    @builds = @project.pipelines.find_by_sha(@build.sha).builds.order('id DESC')
    @builds = @builds.where("id not in (?)", @build.id)
    @pipeline = @build.pipeline

    respond_to do |format|
      format.html
      format.json do
        render json: @build.to_json(methods: :trace_html)
      end
    end
  end

  def trace
    respond_to do |format|
      format.json do
        render json: @build.trace_with_state(params[:state].presence).merge!(id: @build.id, status: @build.status)
      end
    end
  end

  def retry
    return render_404 unless @build.retryable?

    build = Ci::Build.retry(@build, current_user)
    redirect_to build_path(build)
  end

  def play
    return render_404 unless @build.playable?

    build = @build.play(current_user)
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

  def raw
    if @build.has_trace_file?
      send_file @build.trace_file_path, type: 'text/plain; charset=utf-8', disposition: 'inline'
    else
      render_404
    end
  end

  private

  def build
    @build ||= project.builds.find_by!(id: params[:id])
  end

  def build_path(build)
    namespace_project_build_path(build.project.namespace, build.project, build)
  end
end
