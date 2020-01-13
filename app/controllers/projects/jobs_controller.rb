# frozen_string_literal: true

class Projects::JobsController < Projects::ApplicationController
  include SendFileUpload
  include ContinueParams

  before_action :build, except: [:index]
  before_action :authorize_read_build!
  before_action :authorize_update_build!,
    except: [:index, :show, :status, :raw, :trace, :erase]
  before_action :authorize_erase_build!, only: [:erase]
  before_action :authorize_use_build_terminal!, only: [:terminal, :terminal_websocket_authorize]
  before_action :verify_api_request!, only: :terminal_websocket_authorize
  before_action only: [:show] do
    push_frontend_feature_flag(:job_log_json, project, default_enabled: true)
  end

  layout 'project'

  def index
    # We need all builds for tabs counters
    @all_builds = JobsFinder.new(current_user: current_user, project: @project).execute

    @scope = params[:scope]
    @builds = JobsFinder.new(current_user: current_user, project: @project, params: params).execute
    @builds = @builds.eager_load_everything
    @builds = @builds.page(params[:page]).per(30).without_count
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
          build.trace.being_watched!

          # TODO: when the feature flag is removed we should not pass
          # content_format to serialize method.
          content_format = Feature.enabled?(:job_log_json, @project, default_enabled: true) ? :json : :html

          build_trace = Ci::BuildTrace.new(
            build: @build,
            stream: stream,
            state: params[:state],
            content_format: content_format)

          render json: BuildTraceSerializer
            .new(project: @project, current_user: @current_user)
            .represent(build_trace)
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

    build = @build.play(current_user, play_params[:job_variables_attributes])
    redirect_to build_path(build)
  end

  def cancel
    return respond_422 unless @build.cancelable?

    @build.cancel

    if continue_params[:to]
      redirect_to continue_params[:to]
    else
      redirect_to builds_project_pipeline_path(@project, @build.pipeline.id)
    end
  end

  def unschedule
    return respond_422 unless @build.scheduled?

    @build.unschedule!
    redirect_to build_path(@build)
  end

  def status
    render json: BuildSerializer
      .new(project: @project, current_user: @current_user)
      .represent_status(@build)
  end

  def erase
    if @build.erase(erased_by: current_user)
      redirect_to project_job_path(project, @build),
                notice: _("Job has been successfully erased!")
    else
      respond_422
    end
  end

  def raw
    if trace_artifact_file
      workhorse_set_content_type!
      send_upload(trace_artifact_file,
                  send_params: raw_send_params,
                  redirect_params: raw_redirect_params)
    else
      build.trace.read do |stream|
        if stream.file?
          workhorse_set_content_type!
          send_file stream.path, type: 'text/plain; charset=utf-8', disposition: 'inline'
        else
          # In this case we can't use workhorse_set_content_type! and let
          # Workhorse handle the response because the data is streamed directly
          # to the user but, because we have the trace content, we can calculate
          # the proper content type and disposition here.
          raw_data = stream.raw
          send_data raw_data, type: 'text/plain; charset=utf-8', disposition: raw_trace_content_disposition(raw_data), filename: 'job.log'
        end
      end
    end
  end

  def terminal
  end

  # GET .../terminal.ws : implemented in gitlab-workhorse
  def terminal_websocket_authorize
    set_workhorse_internal_api_content_type
    render json: Gitlab::Workhorse.channel_websocket(@build.terminal_specification)
  end

  private

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

  def play_params
    params.permit(job_variables_attributes: %i[key secret_value])
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

  def raw_trace_content_disposition(raw_data)
    mime_type = MimeMagic.by_magic(raw_data)

    # if mime_type is nil can also represent 'text/plain'
    return 'inline' if mime_type.nil? || mime_type.type == 'text/plain'

    'attachment'
  end
end

Projects::JobsController.prepend_if_ee('EE::Projects::JobsController')
