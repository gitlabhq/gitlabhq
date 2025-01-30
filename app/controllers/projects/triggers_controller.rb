# frozen_string_literal: true

class Projects::TriggersController < Projects::ApplicationController
  before_action :authorize_manage_trigger_on_project!
  before_action :authorize_manage_trigger!, except: [:index, :create]

  before_action :authorize_admin_trigger!, only: [:update]
  before_action :trigger, only: [:update, :destroy]

  layout 'project_settings'

  feature_category :continuous_integration
  urgency :low

  def index
    redirect_to project_settings_ci_cd_path(@project, anchor: 'js-pipeline-triggers')
  end

  def create
    response = ::Ci::PipelineTriggers::CreateService.new(
      project: project,
      user: current_user,
      description: trigger_params[:description],
      expires_at: trigger_params[:expires_at]
    ).execute

    @trigger = response.payload[:trigger]

    if response.success?
      flash[:notice] = _('Trigger token was created successfully.')
    else
      flash[:alert] = response.message
    end

    redirect_to project_settings_ci_cd_path(@project, anchor: 'js-pipeline-triggers')
  end

  def update
    response = ::Ci::PipelineTriggers::UpdateService.new(user: current_user, trigger: trigger, description: trigger_params[:description]).execute

    if response.success?
      redirect_to project_settings_ci_cd_path(@project, anchor: 'js-pipeline-triggers'), notice: _('Trigger token was successfully updated.')
    else
      render action: "edit"
    end
  end

  def destroy
    response = ::Ci::PipelineTriggers::DestroyService.new(user: current_user, trigger: trigger).execute

    if response.success?
      flash[:notice] = _("Trigger token removed.")
    else
      flash[:alert] = response.message
    end

    redirect_to project_settings_ci_cd_path(@project, anchor: 'js-pipeline-triggers'), status: :found
  end

  private

  def authorize_manage_trigger!
    access_denied! unless can?(current_user, :manage_trigger, trigger)
  end

  def authorize_manage_trigger_on_project!
    access_denied! unless can?(current_user, :manage_trigger, project)
  end

  def authorize_admin_trigger!
    access_denied! unless can?(current_user, :admin_trigger, trigger)
  end

  def trigger
    @trigger ||= project.triggers.find(params[:id])
      .present(current_user: current_user)
  end

  def trigger_params
    params.require(:trigger).permit(:description, :expires_at)
  end
end
