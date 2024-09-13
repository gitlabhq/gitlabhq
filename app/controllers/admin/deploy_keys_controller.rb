# frozen_string_literal: true

class Admin::DeployKeysController < Admin::ApplicationController
  before_action :deploy_keys, only: [:index]
  before_action :deploy_key, only: [:destroy, :edit, :update]

  feature_category :continuous_delivery
  urgency :low

  def index; end

  def new
    @deploy_key = deploy_keys.new
  end

  def create
    @deploy_key = DeployKeys::CreateService.new(current_user, create_params.merge(public: true)).execute
    if @deploy_key.persisted?
      redirect_to admin_deploy_keys_path
    else
      render 'new'
    end
  end

  def edit; end

  def update
    if deploy_key.update(update_params)
      flash[:notice] = _('Deploy key was successfully updated.')
      redirect_to admin_deploy_keys_path
    else
      render 'edit'
    end
  end

  def destroy
    deploy_key.destroy

    respond_to do |format|
      format.html { redirect_to admin_deploy_keys_path, status: :found }
      format.json { head :ok }
    end
  end

  protected

  def deploy_key
    @deploy_key ||= deploy_keys.find(params.permit(:id)[:id])
  end

  def deploy_keys
    @deploy_keys ||= DeployKey.are_public
  end

  def create_params
    params.require(:deploy_key).permit(:key, :title, :expires_at)
  end

  def update_params
    params.require(:deploy_key).permit(:title)
  end
end
