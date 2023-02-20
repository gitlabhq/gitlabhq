# frozen_string_literal: true

class Groups::RunnersController < Groups::ApplicationController
  before_action :authorize_read_group_runners!, only: [:index, :show]
  before_action :authorize_update_runner!, only: [:edit, :update, :destroy, :pause, :resume]
  before_action :runner, only: [:edit, :update, :destroy, :pause, :resume, :show]

  feature_category :runner
  urgency :low

  def index
    @group_runner_registration_token = @group.runners_token if can?(current_user, :register_group_runners, group)

    Gitlab::Tracking.event(self.class.name, 'index', user: current_user, namespace: @group)
  end

  def show
  end

  def edit
  end

  def update
    if Ci::Runners::UpdateRunnerService.new(@runner).execute(runner_params).success?
      redirect_to group_runner_path(@group, @runner), notice: _('Runner was successfully updated.')
    else
      render 'edit'
    end
  end

  private

  def runner
    group_params = { group: @group, membership: :all_available }

    @runner ||= Ci::RunnersFinder.new(current_user: current_user, params: group_params).execute
      .except(:limit, :offset)
      .find(params[:id])
  end

  def runner_params
    params.require(:runner).permit(Ci::Runner::FORM_EDITABLE)
  end

  def authorize_update_runner!
    return if can?(current_user, :admin_group_runners, group) && can?(current_user, :update_runner, runner)

    render_404
  end
end

Groups::RunnersController.prepend_mod
