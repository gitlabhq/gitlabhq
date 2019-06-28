# frozen_string_literal: true

class Projects::TriggersController < Projects::ApplicationController
  before_action :authorize_admin_build!
  before_action :authorize_manage_trigger!, except: [:index, :create]
  before_action :authorize_admin_trigger!, only: [:edit, :update]
  before_action :trigger, only: [:edit, :update, :destroy]

  layout 'project_settings'

  def index
    redirect_to project_settings_ci_cd_path(@project, anchor: 'js-pipeline-triggers')
  end

  def create
    @trigger = project.triggers.create(trigger_params.merge(owner: current_user))

    if @trigger.valid?
      flash[:notice] = _('Trigger was created successfully.')
    else
      flash[:alert] = _('You could not create a new trigger.')
    end

    redirect_to project_settings_ci_cd_path(@project, anchor: 'js-pipeline-triggers')
  end

  def edit
  end

  def update
    if trigger.update(trigger_params)
      redirect_to project_settings_ci_cd_path(@project, anchor: 'js-pipeline-triggers'), notice: _('Trigger was successfully updated.')
    else
      render action: "edit"
    end
  end

  def destroy
    if trigger.destroy
      flash[:notice] = _("Trigger removed.")
    else
      flash[:alert] = _("Could not remove the trigger.")
    end

    redirect_to project_settings_ci_cd_path(@project, anchor: 'js-pipeline-triggers'), status: :found
  end

  private

  def authorize_manage_trigger!
    access_denied! unless can?(current_user, :manage_trigger, trigger)
  end

  def authorize_admin_trigger!
    access_denied! unless can?(current_user, :admin_trigger, trigger)
  end

  def trigger
    @trigger ||= project.triggers.find(params[:id])
      .present(current_user: current_user)
  end

  def trigger_params
    params.require(:trigger).permit(:description)
  end
end
