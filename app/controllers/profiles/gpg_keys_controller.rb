class Profiles::GpgKeysController < Profiles::ApplicationController
  before_action :set_gpg_key, only: [:destroy, :revoke]

  def index
    @gpg_keys = current_user.gpg_keys.with_subkeys
    @gpg_key = GpgKey.new
  end

  def create
    @gpg_key = GpgKeys::CreateService.new(current_user, gpg_key_params).execute

    if @gpg_key.persisted?
      redirect_to profile_gpg_keys_path
    else
      @gpg_keys = current_user.gpg_keys.select(&:persisted?)
      render :index
    end
  end

  def destroy
    @gpg_key.destroy

    respond_to do |format|
      format.html { redirect_to profile_gpg_keys_url, status: 302 }
      format.js { head :ok }
    end
  end

  def revoke
    @gpg_key.revoke

    respond_to do |format|
      format.html { redirect_to profile_gpg_keys_url, status: 302 }
      format.js { head :ok }
    end
  end

  private

  def gpg_key_params
    params.require(:gpg_key).permit(:key)
  end

  def set_gpg_key
    @gpg_key = current_user.gpg_keys.find(params[:id])
  end
end
