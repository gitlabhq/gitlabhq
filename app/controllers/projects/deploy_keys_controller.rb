class Projects::DeployKeysController < Projects::ApplicationController
  include RepositorySettingsRedirect
  respond_to :html

  # Authorize
  before_action :authorize_admin_project!

  layout "project_settings"

  def index
    redirect_to_repository_settings(@project)
  end

  def new
    redirect_to_repository_settings(@project)
  end

  def create
    @key = DeployKey.new(deploy_key_params.merge(user: current_user))

    unless @key.valid? && @project.deploy_keys << @key
      flash[:alert] = @key.errors.full_messages.join(', ').html_safe      
    end
    redirect_to_repository_settings(@project)
  end

  def enable
    Projects::EnableDeployKeyService.new(@project, current_user, params).execute

    redirect_to_repository_settings(@project)
  end

  def disable
    @project.deploy_keys_projects.find_by(deploy_key_id: params[:id]).destroy

    redirect_to_repository_settings(@project)
  end

  protected

  def deploy_key_params
    params.require(:deploy_key).permit(:key, :title, :can_push)
  end
end
