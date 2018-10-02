# frozen_string_literal: true

class Projects::JobsController < Projects::ApplicationController
  include SendFileUpload

  before_action :build,
    only: [:show, :cancel, :retry, :play, :erase, :trace, :raw, :status, :terminal, :terminal_websocket_authorize]
  before_action :authorize_read_build!,
    only: [:show, :cancel, :retry, :play, :erase, :trace, :raw, :status, :terminal, :terminal_websocket_authorize]
  before_action :authorize_update_build!,
    only: [:cancel, :retry, :play, :terminal, :terminal_websocket_authorize]
  before_action :authorize_erase_build!, only: [:erase]
  before_action :authorize_use_build_terminal!, only: [:terminal, :terminal_websocket_authorize]
  before_action :verify_api_request!, only: :terminal_websocket_authorize

  layout 'project'

  # rubocop: disable CodeReuse/ActiveRecord
  def index
    return access_denied! unless can?(current_user, :read_build, project)

    @scope = params[:scope]
    @all_builds = project.builds.relevant
    @builds = @all_builds.order('ci_builds.id DESC')
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
    @builds = @builds.includes([
      { pipeline: :project },
      :project,
      :tags
    ])
    @builds = @builds.page(params[:page]).per(30).without_count
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def cancel_all
    return access_denied! unless can?(current_user, :update_build, project)

    project.builds.running_or_pending.each do |build|
      build.cancel if can?(current_user, :update_build, build)
    end

    redirect_to project_jobs_path(project)
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def show
    @pipeline = @build.pipeline
    @builds = @pipeline.builds
      .order('id DESC')
      .present(current_user: current_user)

    respond_to do |format|
      format.html
      format.json do
        Gitlab::PollingInterval.set_header(response, interval: 10_000)

        render json: BuildSerializer
          .new(project: @project, current_user: @current_user)
          .represent(@build, {}, BuildDetailsEntity)
      end
    end
  end
  # rubocop: enable CodeReuse/ActiveRecord

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

    respond_to do |format|
      format.html { redirect_to build_path(build) }
      format.json { render_build(build) }
    end
  end

  def play
    return respond_422 unless @build.playable?

    build = @build.play(current_user)
    redirect_to build_path(build)
  end

  def cancel
    return respond_422 unless @build.cancelable?

    @build.cancel

    respond_to do |format|
      format.html { redirect_to build_path(@build) }
      format.json { head :ok }
    end
  end

  def status
    render_build(@build)
  end

  def erase
    if @build.erase(erased_by: current_user)
      redirect_to project_job_path(project, @build),
                notice: "Job has been successfully erased!"
    else
      respond_422
    end
  end

  def raw
    if trace_artifact_file
      send_upload(trace_artifact_file,
                  send_params: raw_send_params,
                  redirect_params: raw_redirect_params)
    else
      build.trace.read do |stream|
        if stream.file?
          send_file stream.path, type: 'text/plain; charset=utf-8', disposition: 'inline'
        else
          send_data stream.raw, type: 'text/plain; charset=utf-8', disposition: 'inline', filename: 'job.log'
        end
      end
    end
  end

  def terminal
  end

  # GET .../terminal.ws : implemented in gitlab-workhorse
  def terminal_websocket_authorize
    set_workhorse_internal_api_content_type
    render json: Gitlab::Workhorse.terminal_websocket(@build.terminal_specification)
  end

  private

  def authorize_read_build!
    return access_denied! unless can?(current_user, :read_build, build)
  end

  def authorize_update_build!
    return access_denied! unless can?(current_user, :update_build, build)
  end

  def authorize_erase_build!
    return access_denied! unless can?(current_user, :erase_build, build)
  end

  def authorize_use_build_terminal!
    return access_denied! unless can?(current_user, :create_build_terminal, build)
  end

  def verify_api_request!
    Gitlab::Workhorse.verify_api_request!(request.headers)
  end

  def raw_send_params
    { type: 'text/plain; charset=utf-8', disposition: 'inline' }
  end

  def raw_redirect_params
    { query: { 'response-content-type' => 'text/plain; charset=utf-8', 'response-content-disposition' => 'inline' } }
  end

  def trace_artifact_file
    @trace_artifact_file ||= build.job_artifacts_trace&.file
  end

  def build
    @build ||= project.builds.find(params[:id])
      .present(current_user: current_user)
  end

  def build_path(build)
    project_job_path(build.project, build)
  end

  def render_build(current_build)
    render json: BuildSerializer
      .new(project: @project, current_user: @current_user)
      .represent_status(current_build)
  end
end
