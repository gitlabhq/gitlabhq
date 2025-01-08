# frozen_string_literal: true

class Projects::JobsController < Projects::ApplicationController
  include Ci::AuthBuildTrace
  include SendFileUpload
  include ContinueParams
  include ProjectStatsRefreshConflictsGuard

  urgency :low, [:index, :show, :trace, :retry, :play, :cancel, :unschedule, :erase, :viewer, :raw, :test_report_summary]

  before_action :find_job_as_build, except: [:index, :play, :retry, :show]
  before_action :find_job_as_processable, only: [:play, :retry, :show]
  before_action :authorize_read_build_trace!, only: [:trace, :viewer, :raw]
  before_action :authorize_read_build!, except: [:test_report_summary]
  before_action :authorize_read_build_report_results!, only: [:test_report_summary]
  before_action :authorize_update_build!,
    except: [:index, :show, :viewer, :raw, :trace, :erase, :cancel, :unschedule, :test_report_summary]
  before_action :authorize_cancel_build!, only: [:cancel]
  before_action :authorize_erase_build!, only: [:erase]
  before_action :authorize_use_build_terminal!, only: [:terminal, :terminal_websocket_authorize]
  before_action :verify_api_request!, only: :terminal_websocket_authorize
  before_action :authorize_create_proxy_build!, only: :proxy_websocket_authorize
  before_action :verify_proxy_request!, only: :proxy_websocket_authorize
  before_action :reject_if_build_artifacts_size_refreshing!, only: [:erase]
  before_action :push_filter_by_name, only: [:index]
  layout 'project'

  feature_category :continuous_integration
  urgency :low

  def index; end

  def show
    if @build.instance_of?(::Ci::Bridge)
      redirect_to project_pipeline_path(@build.downstream_pipeline.project, @build.downstream_pipeline.id)
    end

    respond_to do |format|
      format.html
      format.json do
        Gitlab::PollingInterval.set_header(response, interval: 10_000)

        render json: Ci::JobSerializer
          .new(project: @project, current_user: @current_user)
          .represent(
            @build.present(current_user: current_user),
            {
              # Pipeline will show all failed builds by default if not using disable_failed_builds
              disable_coverage: true,
              disable_failed_builds: true
            },
            BuildDetailsEntity
          )
      end
    end
  end

  def trace
    @build.trace.being_watched! if @build.running?

    if @build.has_trace?
      @build.trace.read do |stream|
        respond_to do |format|
          format.json do
            build_trace = Ci::BuildTrace.new(
              build: @build,
              stream: stream,
              state: params[:state])

            render json: BuildTraceSerializer
              .new(project: @project, current_user: @current_user)
              .represent(build_trace)
          end
        end
      end
    else
      head :no_content
    end
  end

  def retry
    Gitlab::QueryLimiting.disable!('https://gitlab.com/gitlab-org/gitlab/-/issues/424184')

    response = Ci::RetryJobService.new(project, current_user).execute(@build)

    if response.success?
      if @build.is_a?(::Ci::Build)
        redirect_to build_path(response[:job])
      else
        head :ok
      end
    else
      respond_422
    end
  end

  def play
    return respond_422 unless @build.playable?

    job = @build.play(current_user, play_params[:job_variables_attributes])

    if job.is_a?(Ci::Bridge)
      redirect_to pipeline_path(job.pipeline)
    else
      redirect_to build_path(job)
    end
  end

  def cancel
    service_response = Ci::BuildCancelService.new(@build, current_user).execute

    if service_response.success?
      destination = continue_params[:to].presence || builds_project_pipeline_path(@project, @build.pipeline.id)
      redirect_to destination
    elsif service_response.http_status == :forbidden
      access_denied!
    else
      head service_response.http_status
    end
  end

  def unschedule
    service_response = Ci::BuildUnscheduleService.new(@build, current_user).execute

    if service_response.success?
      redirect_to build_path(@build)
    elsif service_response.http_status == :forbidden
      access_denied!
    else
      head service_response.http_status
    end
  end

  def erase
    service_response = Ci::BuildEraseService.new(@build, current_user).execute

    if service_response.success?
      redirect_to project_job_path(project, @build), notice: _("Job has been successfully erased!")
    else
      head service_response.http_status
    end
  end

  def raw
    if @build.trace.archived?
      workhorse_set_content_type!
      send_upload(@build.job_artifacts_trace.file, send_params: raw_send_params, redirect_params: raw_redirect_params, proxy: params[:proxy])
    else
      @build.trace.read do |stream|
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

  def viewer; end

  def test_report_summary
    return not_found unless @build.report_results.present?

    summary = Gitlab::Ci::Reports::TestReportSummary.new(@build.report_results)

    respond_to do |format|
      format.json do
        render json: TestReportSummarySerializer
                       .new(project: project, current_user: @current_user)
                       .represent(summary)
      end
    end
  end

  def terminal; end

  # GET .../terminal.ws : implemented in gitlab-workhorse
  def terminal_websocket_authorize
    set_workhorse_internal_api_content_type
    render json: Gitlab::Workhorse.channel_websocket(@build.terminal_specification)
  end

  def proxy_websocket_authorize
    render json: proxy_websocket_service(build_service_specification)
  end

  private

  attr_reader :build

  def authorize_read_build_report_results!
    access_denied! unless can?(current_user, :read_build_report_results, build)
  end

  def authorize_update_build!
    access_denied! unless can?(current_user, :update_build, @build)
  end

  def authorize_cancel_build!
    access_denied! unless can?(current_user, :cancel_build, @build)
  end

  def authorize_erase_build!
    access_denied! unless can?(current_user, :erase_build, @build)
  end

  def authorize_use_build_terminal!
    access_denied! unless can?(current_user, :create_build_terminal, @build)
  end

  def authorize_create_proxy_build!
    access_denied! unless can?(current_user, :create_build_service_proxy, @build)
  end

  def verify_api_request!
    Gitlab::Workhorse.verify_api_request!(request.headers)
  end

  def verify_proxy_request!
    verify_api_request!
    set_workhorse_internal_api_content_type
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

  def find_job_as_build
    @build = project.builds.find(params[:id])
  end

  def find_job_as_processable
    @build = project.processables.find(params[:id])
  end

  def build_path(build)
    project_job_path(build.project, build)
  end

  def raw_trace_content_disposition(raw_data)
    mime_type = Gitlab::Utils::MimeType.from_string(raw_data)

    # if mime_type is nil can also represent 'text/plain'
    return 'inline' if mime_type.nil? || mime_type == 'text/plain'

    'attachment'
  end

  def build_service_specification
    @build.service_specification(
      service: params['service'],
      port: params['port'],
      path: params['path'],
      subprotocols: proxy_subprotocol
    )
  end

  def proxy_subprotocol
    # This will allow to reuse the same subprotocol set
    # in the original websocket connection
    request.headers['HTTP_SEC_WEBSOCKET_PROTOCOL'].presence || ::Ci::BuildRunnerSession::TERMINAL_SUBPROTOCOL
  end

  # This method provides the information to Workhorse
  # about the service we want to proxy to.
  # For security reasons, in case this operation is started by JS,
  # it's important to use only sourced GitLab JS code
  def proxy_websocket_service(service)
    service[:url] = ::Gitlab::UrlHelpers.as_wss(service[:url])

    ::Gitlab::Workhorse.channel_websocket(service)
  end

  def push_filter_by_name
    push_frontend_feature_flag(:fe_search_build_by_name, @project)
  end
end

Projects::JobsController.prepend_mod_with('Projects::JobsController')
