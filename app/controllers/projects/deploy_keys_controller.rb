# frozen_string_literal: true

class Projects::DeployKeysController < Projects::ApplicationController
  include RepositorySettingsRedirect
  respond_to :html

  # Authorize
  before_action :authorize_admin_project!
  before_action :authorize_update_deploy_key!, only: [:edit, :update]

  layout 'project_settings'

  def index
    respond_to do |format|
      format.html { redirect_to_repository }
      format.json do
        render json: Projects::Settings::DeployKeysPresenter.new(@project, current_user: current_user).as_json
      end
    end
  end

  def new
    redirect_to_repository
  end

  def create
    @key = DeployKeys::CreateService.new(current_user, create_params).execute(project: @project)

    unless @key.valid?
      flash[:alert] = @key.errors.full_messages.join(', ').html_safe
    end

    redirect_to_repository
  end

  def edit
  end

  def update
    access_denied! unless deploy_key

    if deploy_key.update(update_params)
      flash[:notice] = _('Deploy key was successfully updated.')
      redirect_to_repository
    else
      render 'edit'
    end
  end

  def enable
    key = Projects::EnableDeployKeyService.new(@project, current_user, params).execute

    return render_404 unless key

    respond_to do |format|
      format.html { redirect_to_repository }
      format.json { head :ok }
    end
  end

  def disable
    deploy_key_project = Projects::DisableDeployKeyService.new(@project, current_user, params).execute

    return render_404 unless deploy_key_project

    respond_to do |format|
      format.html { redirect_to_repository }
      format.json { head :ok }
    end
  end

  protected

  def deploy_key
    @deploy_key ||= DeployKey.find(params[:id])
  end

  def deploy_keys_project
    @deploy_keys_project ||= deploy_key.deploy_keys_project_for(@project)
  end

  def create_params
    create_params = params.require(:deploy_key)
                          .permit(:key, :title, deploy_keys_projects_attributes: [:can_push])
    create_params.dig(:deploy_keys_projects_attributes, '0')&.merge!(project_id: @project.id)
    create_params
  end

  def update_params
    permitted_params = [deploy_keys_projects_attributes: [:can_push]]
    permitted_params << :title if can?(current_user, :update_deploy_key, deploy_key)

    key_update_params = params.require(:deploy_key).permit(*permitted_params)
    key_update_params.dig(:deploy_keys_projects_attributes, '0')&.merge!(id: deploy_keys_project.id)
    key_update_params
  end

  def authorize_update_deploy_key!
    if !can?(current_user, :update_deploy_key, deploy_key) &&
        !can?(current_user, :update_deploy_keys_project, deploy_keys_project)
      access_denied!
    end
  end

  private

  def redirect_to_repository
    redirect_to_repository_settings(@project, anchor: 'js-deploy-keys-settings')
  end
end
