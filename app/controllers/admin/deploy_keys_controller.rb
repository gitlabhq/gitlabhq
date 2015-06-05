class Admin::DeployKeysController < Admin::ApplicationController
  before_action :deploy_keys, only: [:index]
  before_action :deploy_key, only: [:destroy]

  def index
  end

  def new
    @deploy_key = deploy_keys.new
  end

  def create
    @deploy_key = deploy_keys.new(deploy_key_params)

    if @deploy_key.save
      redirect_to admin_deploy_keys_path
    else
      render "new"
    end
  end

  def destroy
    deploy_key.destroy

    respond_to do |format|
      format.html { redirect_to admin_deploy_keys_path }
      format.json { head :ok }
    end
  end

  protected

  def deploy_key
    @deploy_key ||= deploy_keys.find(params[:id])
  end

  def deploy_keys
    @deploy_keys ||= DeployKey.are_public
  end

  def deploy_key_params
    params.require(:deploy_key).permit(:key, :title)
  end
end
