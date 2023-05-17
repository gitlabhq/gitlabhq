# frozen_string_literal: true

class Groups::RunnersController < Groups::ApplicationController
  before_action :authorize_read_group_runners!, only: [:index, :show]
  before_action :authorize_create_group_runners!, only: [:new, :register]
  before_action :authorize_update_runner!, only: [:edit, :update, :destroy, :pause, :resume]
  before_action :runner, only: [:edit, :update, :destroy, :pause, :resume, :show, :register]

  before_action only: [:index] do
    push_frontend_feature_flag(:create_runner_workflow_for_namespace, group)
  end

  feature_category :runner
  urgency :low

  def index
    @group_runner_registration_token = @group.runners_token if can?(current_user, :register_group_runners, group)
    @group_new_runner_path = new_group_runner_path(@group) if can?(current_user, :create_runner, group)

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

  def new
    render_404 unless create_runner_workflow_for_namespace_enabled?
  end

  def register
    render_404 unless create_runner_workflow_for_namespace_enabled? && runner.registration_available?
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

  def authorize_create_group_runners!
    return if can?(current_user, :create_runner, group)

    render_404
  end

  def create_runner_workflow_for_namespace_enabled?
    Feature.enabled?(:create_runner_workflow_for_namespace, group)
  end
end

Groups::RunnersController.prepend_mod
