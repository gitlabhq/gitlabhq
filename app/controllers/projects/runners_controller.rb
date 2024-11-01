# frozen_string_literal: true

class Projects::RunnersController < Projects::ApplicationController
  before_action :authorize_read_runner!
  before_action :authorize_admin_runner!, except: [:index, :show]
  before_action :authorize_create_runner!, only: [:new, :register]
  before_action :runner, only: [:edit, :destroy, :pause, :resume, :show, :register]

  feature_category :runner
  urgency :low

  def index
    redirect_to project_settings_ci_cd_path(@project, anchor: 'js-runners-settings')
  end

  def edit; end

  def new; end

  def register
    render_404 unless runner.registration_available?
  end

  def destroy
    Ci::Runners::UnregisterRunnerService.new(@runner, current_user).execute if @runner.only_for?(project)

    redirect_to project_runners_path(@project), status: :found
  end

  def resume
    if Ci::Runners::UpdateRunnerService.new(current_user, runner).execute(active: true).success?
      redirect_to project_runners_path(@project), notice: _('Runner was successfully updated.')
    else
      redirect_to project_runners_path(@project), alert: _('Runner was not updated.')
    end
  end

  def pause
    if Ci::Runners::UpdateRunnerService.new(current_user, @runner).execute(active: false).success?
      redirect_to project_runners_path(@project), notice: _('Runner was successfully updated.')
    else
      redirect_to project_runners_path(@project), alert: _('Runner was not updated.')
    end
  end

  def show; end

  def toggle_shared_runners
    update_params = { shared_runners_enabled: !project.shared_runners_enabled }
    result = Projects::UpdateService.new(project, current_user, update_params).execute

    if result[:status] == :success
      render json: {}, status: :ok
    else
      render json: { error: result[:message] }, status: :unauthorized
    end
  end

  def toggle_group_runners
    project.toggle_ci_cd_settings!(:group_runners_enabled)

    redirect_to project_settings_ci_cd_path(@project, anchor: 'js-runners-settings')
  end

  protected

  def runner
    @runner ||= project.runners.find(params[:id])
  end

  def runner_params
    params.require(:runner).permit(Ci::Runner::FORM_EDITABLE)
  end
end

Projects::RunnersController.prepend_mod
