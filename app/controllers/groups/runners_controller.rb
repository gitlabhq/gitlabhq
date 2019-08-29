# frozen_string_literal: true

class Groups::RunnersController < Groups::ApplicationController
  # Proper policies should be implemented per
  # https://gitlab.com/gitlab-org/gitlab-ce/issues/45894
  before_action :authorize_admin_group!

  before_action :runner, only: [:edit, :update, :destroy, :pause, :resume, :show]

  def show
    render 'shared/runners/show'
  end

  def edit
  end

  def update
    if Ci::UpdateRunnerService.new(@runner).update(runner_params)
      redirect_to group_runner_path(@group, @runner), notice: _('Runner was successfully updated.')
    else
      render 'edit'
    end
  end

  def destroy
    @runner.destroy

    redirect_to group_settings_ci_cd_path(@group, anchor: 'runners-settings'), status: :found
  end

  def resume
    if Ci::UpdateRunnerService.new(@runner).update(active: true)
      redirect_to group_settings_ci_cd_path(@group, anchor: 'runners-settings'), notice: _('Runner was successfully updated.')
    else
      redirect_to group_settings_ci_cd_path(@group, anchor: 'runners-settings'), alert: _('Runner was not updated.')
    end
  end

  def pause
    if Ci::UpdateRunnerService.new(@runner).update(active: false)
      redirect_to group_settings_ci_cd_path(@group, anchor: 'runners-settings'), notice: _('Runner was successfully updated.')
    else
      redirect_to group_settings_ci_cd_path(@group, anchor: 'runners-settings'), alert: _('Runner was not updated.')
    end
  end

  private

  def runner
    @runner ||= @group.runners.find(params[:id])
  end

  def runner_params
    params.require(:runner).permit(Ci::Runner::FORM_EDITABLE)
  end
end
