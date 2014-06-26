class Projects::DeployKeysController < Projects::ApplicationController
  respond_to :html

  # Authorize
  before_filter :authorize_admin_project!

  layout "project_settings"

  def index
    @enabled_keys = @project.deploy_keys
    @available_keys = available_keys - @enabled_keys
  end

  def show
    @key = @project.deploy_keys.find(params[:id])
  end

  def new
    @key = @project.deploy_keys.new

    respond_with(@key)
  end

  def create
    @key = DeployKey.new(deploy_key_params)

    if @key.valid? && @project.deploy_keys << @key
      redirect_to project_deploy_keys_path(@project)
    else
      render "new"
    end
  end

  def destroy
    @key = @project.deploy_keys.find(params[:id])
    @key.destroy

    respond_to do |format|
      format.html { redirect_to project_deploy_keys_url }
      format.js { render nothing: true }
    end
  end

  def enable
    project.deploy_keys << available_keys.find(params[:id])

    redirect_to project_deploy_keys_path(@project)
  end

  def disable
    @project.deploy_keys_projects.where(deploy_key_id: params[:id]).last.destroy

    redirect_to project_deploy_keys_path(@project)
  end

  protected

  def available_keys
    @available_keys ||= current_user.accessible_deploy_keys
  end

  def deploy_key_params
    params.require(:deploy_key).permit(:key, :title)
  end
end
