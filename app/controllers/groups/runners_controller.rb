# frozen_string_literal: true

class Groups::RunnersController < Groups::ApplicationController
  # overrriden in EE
  def self.needs_authorize_read_group_runners
    [:index, :show]
  end

  before_action :authorize_read_group_runners!, only: needs_authorize_read_group_runners
  before_action :authorize_create_group_runners!, only: [:new, :register]
  before_action :authorize_update_runner!, only: [:edit, :update]
  before_action :runner, only: [:edit, :update, :show, :register]

  feature_category :runner
  urgency :low

  def index
    @allow_registration_token = @group.allow_runner_registration_token?
    @group_runner_registration_token = @group.runners_token if can?(current_user, :register_group_runners, group)

    @group_new_runner_path = new_group_runner_path(@group) if can?(current_user, :create_runner, group)

    Gitlab::Tracking.event(self.class.name, 'index', user: current_user, namespace: @group)
  end

  def show; end

  def edit; end

  def update
    if Ci::Runners::UpdateRunnerService.new(current_user, @runner).execute(runner_params).success?
      redirect_to group_runner_path(@group, @runner), notice: _('Runner was successfully updated.')
    else
      render 'edit'
    end
  end

  def new; end

  def register
    render_404 unless runner.registration_available?
  end

  private

  def runner
    group_params = { group: @group, membership: :all_available }

    @runner ||= Ci::RunnersFinder.new(current_user: current_user, params: group_params).execute
      .except(:limit, :offset)
      .find(params[:id])
  rescue Gitlab::Access::AccessDeniedError
    nil
  end

  def runner_params
    params.require(:runner).permit(Ci::Runner::FORM_EDITABLE)
  end

  def authorize_update_runner!
    return if can?(current_user, :update_runner, runner)

    render_404
  end

  def authorize_create_group_runners!
    return if can?(current_user, :create_runner, group)

    render_404
  end
end

Groups::RunnersController.prepend_mod
