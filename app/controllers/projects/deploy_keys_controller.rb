class Projects::DeployKeysController < Projects::ApplicationController
  respond_to :html

  # Authorize
  before_action :authorize_admin_project!

  layout "project_settings"

  def index
    @enabled_keys = @project.deploy_keys

    @available_keys         = accessible_keys - @enabled_keys
    @available_project_keys = current_user.project_deploy_keys - @enabled_keys
    @available_public_keys  = DeployKey.are_public - @enabled_keys

    # Public keys that are already used by another accessible project are already
    # in @available_project_keys.
    @available_public_keys -= @available_project_keys
  end

  def new
    @key = @project.deploy_keys.new

    respond_with(@key)
  end

  def create
    @key = DeployKey.new(deploy_key_params)

    if @key.valid? && @project.deploy_keys << @key
      redirect_to namespace_project_deploy_keys_path(@project.namespace,
                                                     @project)
    else
      render "new"
    end
  end

  def enable
    @key = accessible_keys.find(params[:id])
    @project.deploy_keys << @key

    redirect_to namespace_project_deploy_keys_path(@project.namespace,
                                                   @project)
  end

  def disable
    @project.deploy_keys_projects.find_by(deploy_key_id: params[:id]).destroy

    redirect_back_or_default(default: { action: 'index' })
  end

  protected

  def accessible_keys
    @accessible_keys ||= current_user.accessible_deploy_keys
  end

  def deploy_key_params
    params.require(:deploy_key).permit(:key, :title)
  end
end
