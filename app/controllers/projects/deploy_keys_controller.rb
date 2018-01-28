class Projects::DeployKeysController < Projects::ApplicationController
  include RepositorySettingsRedirect
  respond_to :html

  # Authorize
  before_action :authorize_admin_project!
  before_action :authorize_update_deploy_key!, only: [:edit, :update]

  layout 'project_settings'

  def index
    respond_to do |format|
      format.html { redirect_to_repository_settings(@project) }
      format.json do
        render json: Projects::Settings::DeployKeysPresenter.new(@project, current_user: current_user).as_json
      end
    end
  end

  def new
    redirect_to_repository_settings(@project)
  end

  def create
    @key = DeployKeys::CreateService.new(current_user, create_params).execute

    unless @key.valid?
      flash[:alert] = @key.errors.full_messages.join(', ').html_safe
    end

    redirect_to_repository_settings(@project)
  end

  def edit
  end

  def update
    if deploy_key.update_attributes(update_params)
      flash[:notice] = 'Deploy key was successfully updated.'
      redirect_to_repository_settings(@project)
    else
      render 'edit'
    end
  end

  def enable
    Projects::EnableDeployKeyService.new(@project, current_user, params).execute

    respond_to do |format|
      format.html { redirect_to_repository_settings(@project) }
      format.json { head :ok }
    end
  end

  def disable
    deploy_key_project = @project.deploy_keys_projects.find_by(deploy_key_id: params[:id])
    return render_404 unless deploy_key_project

    deploy_key_project.destroy!

    respond_to do |format|
      format.html { redirect_to_repository_settings(@project) }
      format.json { head :ok }
    end
  end

  protected

  def deploy_key
    @deploy_key ||= DeployKey.find(params[:id])
  end

  def create_params
    create_params = params.require(:deploy_key)
                          .permit(:key, :title, deploy_keys_projects_attributes: [:can_push])
    create_params.dig(:deploy_keys_projects_attributes, '0')&.merge!(project_id: @project.id)
    create_params
  end

  def update_params
    params.require(:deploy_key).permit(:title, deploy_keys_projects_attributes: [:id, :can_push])
  end

  def authorize_update_deploy_key!
    access_denied! unless can?(current_user, :update_deploy_key, deploy_key)
  end
end
