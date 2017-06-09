class Projects::BuildsController < Projects::ApplicationController
  before_action :authorize_read_build!

  def index
    redirect_to namespace_project_jobs_path(project.namespace, project)
  end

  def show
<<<<<<< HEAD
    @builds = @project.pipelines.find_by_sha(@build.sha).builds.order('id DESC')
    @builds = @builds.where("id not in (?)", @build.id)
    @pipeline = @build.pipeline
  end

  def trace
    build.trace.read do |stream|
      respond_to do |format|
        format.json do
          result = {
            id: @build.id, status: @build.status, complete: @build.complete?
          }

          if stream.valid?
            stream.limit
            state = params[:state].presence
            trace = stream.html_with_state(state)
            result.merge!(trace.to_h)
          end

          render json: result
        end
      end
    end
  end

  def retry
    return respond_422 unless @build.retryable?

    build = Ci::Build.retry(@build, current_user)
    redirect_to build_path(build)
  end

  def play
    return respond_422 unless @build.playable?

    build = @build.play(current_user)
    redirect_to build_path(build)
  end

  def cancel
    return respond_422 unless @build.cancelable?

    @build.cancel
    redirect_to build_path(@build)
  end

  def status
    render json: BuildSerializer
      .new(project: @project, current_user: @current_user)
      .represent_status(@build)
  end

  def erase
    if @build.erase(erased_by: current_user)
      redirect_to namespace_project_build_path(project.namespace, project, @build),
                notice: "Build has been successfully erased!"
    else
      respond_422
    end
=======
    redirect_to namespace_project_job_path(project.namespace, project, job)
>>>>>>> abc61f260074663e5711d3814d9b7d301d07a259
  end

  def raw
    redirect_to raw_namespace_project_job_path(project.namespace, project, job)
  end

  private

  def job
    @job ||= project.builds.find(params[:id])
  end
end
