# frozen_string_literal: true

class Groups::RunnersController < Groups::ApplicationController
  before_action :authorize_read_group_runners!, only: [:index, :show]
  before_action :authorize_admin_group_runners!, only: [:edit, :update, :destroy, :pause, :resume]
  before_action :runner_list_group_view_vue_ui_enabled, only: [:index]
  before_action :runner, only: [:edit, :update, :destroy, :pause, :resume, :show]

  feature_category :runner

  def index
    finder = Ci::RunnersFinder.new(current_user: current_user, params: { group: @group })
    @group_runners_limited_count = finder.execute.except(:limit, :offset).page.total_count_with_limit(:all, limit: 1000)

    Gitlab::Tracking.event(self.class.name, 'index', user: current_user, namespace: @group)
  end

  def runner_list_group_view_vue_ui_enabled
    render_404 unless Feature.enabled?(:runner_list_group_view_vue_ui, group, default_enabled: :yaml)
  end

  def show
  end

  def edit
  end

  def update
    if Ci::Runners::UpdateRunnerService.new(@runner).update(runner_params)
      redirect_to group_runner_path(@group, @runner), notice: _('Runner was successfully updated.')
    else
      render 'edit'
    end
  end

  def destroy
    if can?(current_user, :delete_runner, @runner)
      Ci::Runners::UnregisterRunnerService.new(@runner, current_user).execute

      redirect_to group_settings_ci_cd_path(@group, anchor: 'runners-settings'), status: :found
    else
      redirect_to group_settings_ci_cd_path(@group, anchor: 'runners-settings'), status: :found, alert: _('Runner cannot be deleted, please contact your administrator.')
    end
  end

  def resume
    if Ci::Runners::UpdateRunnerService.new(@runner).update(active: true)
      redirect_to group_settings_ci_cd_path(@group, anchor: 'runners-settings'), notice: _('Runner was successfully updated.')
    else
      redirect_to group_settings_ci_cd_path(@group, anchor: 'runners-settings'), alert: _('Runner was not updated.')
    end
  end

  def pause
    if Ci::Runners::UpdateRunnerService.new(@runner).update(active: false)
      redirect_to group_settings_ci_cd_path(@group, anchor: 'runners-settings'), notice: _('Runner was successfully updated.')
    else
      redirect_to group_settings_ci_cd_path(@group, anchor: 'runners-settings'), alert: _('Runner was not updated.')
    end
  end

  private

  def runner
    @runner ||= Ci::RunnersFinder.new(current_user: current_user, params: { group: @group }).execute
      .except(:limit, :offset)
      .find(params[:id])
  end

  def runner_params
    params.require(:runner).permit(Ci::Runner::FORM_EDITABLE)
  end
end
