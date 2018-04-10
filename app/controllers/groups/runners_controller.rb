class Groups::RunnersController < Groups::ApplicationController
  before_action :authorize_admin_pipeline!
  before_action :set_runner, only: [:edit, :update, :destroy, :pause, :resume, :show]

  def show
  end

  def edit
  end

  def update
    if Ci::UpdateRunnerService.new(@runner).update(runner_params)
      redirect_to group_runner_path(@group, @runner), notice: 'Runner was successfully updated.'
    else
      render 'edit'
    end
  end

  def destroy
    @runner.destroy

    redirect_to group_settings_ci_cd_path(@group), status: 302
  end

  def resume
    if Ci::UpdateRunnerService.new(@runner).update(active: true)
      redirect_to group_settings_ci_cd_path(@group), notice: 'Runner was successfully updated.'
    else
      redirect_to group_settings_ci_cd_path(@group), alert: 'Runner was not updated.'
    end
  end

  def pause
    if Ci::UpdateRunnerService.new(@runner).update(active: false)
      redirect_to group_settings_ci_cd_path(@group), notice: 'Runner was successfully updated.'
    else
      redirect_to group_settings_ci_cd_path(@group), alert: 'Runner was not updated.'
    end
  end

  private

  def set_runner
    @runner ||= @group.runners.find(params[:id])
  end

  def authorize_admin_pipeline!
    return render_404 unless can?(current_user, :admin_pipeline, group)
  end

  def runner_params
    params.require(:runner).permit(Ci::Runner::FORM_EDITABLE)
  end
end
