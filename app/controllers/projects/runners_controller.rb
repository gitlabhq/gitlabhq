class Projects::RunnersController < Projects::ApplicationController
  before_action :authorize_admin_build!
  before_action :set_runner, only: [:edit, :update, :destroy, :pause, :resume, :show]

  layout 'project_settings'

  def index
    redirect_to project_settings_ci_cd_path(@project)
  end

  def edit
  end

  def update
    if Ci::UpdateRunnerService.new(@runner).update(runner_params)
      redirect_to runner_path(@runner), notice: 'Runner was successfully updated.'
    else
      render 'edit'
    end
  end

  def destroy
    if @runner.only_for?(project)
      @runner.destroy
    end

    redirect_to runners_path(@project), status: 302
  end

  def resume
    if Ci::UpdateRunnerService.new(@runner).update(active: true)
      redirect_to runners_path(@project), notice: 'Runner was successfully updated.'
    else
      redirect_to runners_path(@project), alert: 'Runner was not updated.'
    end
  end

  def pause
    if Ci::UpdateRunnerService.new(@runner).update(active: false)
      redirect_to runners_path(@project), notice: 'Runner was successfully updated.'
    else
      redirect_to runners_path(@project), alert: 'Runner was not updated.'
    end
  end

  def show
  end

  def toggle_shared_runners
    project.toggle!(:shared_runners_enabled)

    redirect_to project_settings_ci_cd_path(@project)
  end

  def toggle_group_runners
    project.toggle_settings!(:group_runners_enabled)

    redirect_to project_settings_ci_cd_path(@project)
  end

  protected

  def set_runner
    @runner ||= project.runners.find(params[:id])
  end

  def runner_params
    params.require(:runner).permit(Ci::Runner::FORM_EDITABLE)
  end
end
