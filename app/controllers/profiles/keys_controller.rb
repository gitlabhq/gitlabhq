class Profiles::KeysController < Profiles::ApplicationController
  skip_before_action :authenticate_user!, only: [:get_keys]

  def index
    @keys = current_user.keys.order_id_desc
    @key = Key.new
  end

  def show
    @key = current_user.keys.find(params[:id])
  end

  def create
    @key = Keys::CreateService.new(current_user, key_params.merge(ip_address: request.remote_ip)).execute

    if @key.persisted?
      redirect_to profile_key_path(@key)
    else
      @keys = current_user.keys.select(&:persisted?)
      render :index
    end
  end

  def destroy
    @key = current_user.keys.find(params[:id])
    @key.destroy

    respond_to do |format|
      format.html { redirect_to profile_keys_url, status: 302 }
      format.js { head :ok }
    end
  end

  # Get all keys of a user(params[:username]) in a text format
  # Helpful for sysadmins to put in respective servers
  def get_keys
    if params[:username].present?
      begin
        user = User.find_by_username(params[:username])
        if user.present?
          render text: user.all_ssh_keys.join("\n"), content_type: "text/plain"
        else
          return render_404
        end
      rescue => e
        render text: e.message
      end
    else
      return render_404
    end
  end

  private

  def key_params
    params.require(:key).permit(:title, :key)
  end
end
