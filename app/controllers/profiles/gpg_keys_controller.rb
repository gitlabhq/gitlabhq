class Profiles::GpgKeysController < Profiles::ApplicationController
  def index
    @gpg_keys = current_user.gpg_keys
    @gpg_key = GpgKey.new
  end

  def create
    @gpg_key = current_user.gpg_keys.new(gpg_key_params)

    if @gpg_key.save
      redirect_to profile_gpg_keys_path
    else
      @gpg_keys = current_user.gpg_keys.select(&:persisted?)
      render :index
    end
  end

  def destroy
    @gpp_key = current_user.gpg_keys.find(params[:id])
    @gpp_key.destroy

    respond_to do |format|
      format.html { redirect_to profile_gpg_keys_url, status: 302 }
      format.js { head :ok }
    end
  end

  private

  def gpg_key_params
    params.require(:gpg_key).permit(:key)
  end
end
