class Projects::EnvironmentScalingsController < Projects::ApplicationController
  before_action :authorize_read_environment!
  before_action :authorize_admin_environment!, only: [:update]
  before_action :environment_scaling, only: [:show, :update]

  def update
    if @environment_scaling.update(scaling_params)
      respond_to do |format|
        format.json { return head status: :ok }
      end
    else
      respond_to do |format|
        format.json { render status: :bad_request, json: @environment_scaling.errors.full_messages }
      end
    end
  end

  private

  def environment_scaling
    environment = project.environments.find(params[:environment_id])
    @environment_scaling ||= environment.scaling || environment.create_scaling(replicas: 1)
  end

  def scaling_params
    params.require(:environment_scaling).permit(:replicas)
  end
end
