# frozen_string_literal: true

class Projects::WebIdeTerminalsController < Projects::ApplicationController
  before_action :authenticate_user!

  before_action :build, except: [:check_config, :create]
  before_action :authorize_create_web_ide_terminal!
  before_action :authorize_read_web_ide_terminal!, except: [:check_config, :create]
  before_action :authorize_update_web_ide_terminal!, only: [:cancel, :retry]

  feature_category :web_ide

  urgency :low, [:check_config]

  def check_config
    return respond_422 unless branch_sha

    result = ::Ide::TerminalConfigService.new(project, current_user, sha: branch_sha).execute

    if result[:status] == :success
      head :ok
    else
      respond_422
    end
  end

  def show
    render_terminal(build)
  end

  def create
    result = ::Ci::CreateWebIdeTerminalService.new(project, current_user, ref: params[:branch]).execute

    if result[:status] == :error
      render status: :bad_request, json: result[:message]
    else
      pipeline = result[:pipeline]
      current_build = pipeline.builds.last

      if current_build
        render_terminal(current_build)
      else
        render status: :bad_request, json: pipeline.errors.full_messages
      end
    end
  end

  def cancel
    return respond_422 unless build.cancelable?

    build.cancel

    head :ok
  end

  def retry
    response = Ci::RetryJobService.new(build.project, current_user).execute(build)

    if response.success?
      render_terminal(response[:job])
    else
      respond_422
    end
  end

  private

  def authorize_create_web_ide_terminal!
    access_denied! unless can?(current_user, :create_web_ide_terminal, project)
  end

  def authorize_read_web_ide_terminal!
    authorize_build_ability!(:read_web_ide_terminal)
  end

  def authorize_update_web_ide_terminal!
    authorize_build_ability!(:update_web_ide_terminal)
  end

  def authorize_build_ability!(ability)
    access_denied! unless can?(current_user, ability, build)
  end

  def build
    @build ||= project.builds.find(params[:id])
  end

  def branch_sha
    return unless params[:branch].present?

    project.commit(params[:branch])&.id
  end

  def render_terminal(current_build)
    render json: WebIdeTerminalSerializer
      .new(project: project, current_user: current_user)
      .represent(current_build)
  end
end
