class Admin::DeployKeysController < Admin::ApplicationController
  before_filter :deploy_key, only: [:show, :destroy]

  def index
    @deploy_keys = DeployKey.are_public
  end

  def show
    
  end

  def new
    @deploy_key = DeployKey.new(public: true)
  end

  def create
    @deploy_key = DeployKey.new(deploy_key_params)
    @deploy_key.public = true

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
    @deploy_key ||= DeployKey.find(params[:id])
  end

  def deploy_key_params
    params.require(:deploy_key).permit(:key, :title)
  end
end
