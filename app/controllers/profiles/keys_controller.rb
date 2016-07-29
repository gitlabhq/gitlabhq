class Profiles::KeysController < Profiles::ApplicationController
  skip_before_action :authenticate_user!, only: [:get_keys]

  def index
    @keys = current_user.keys
    @key = Key.new
  end

  def show
    @key = current_user.keys.find(params[:id])
  end

  # Back-compat: We need to support this URL since git-annex webapp points to it
  def new
    redirect_to profile_keys_path
  end

  def create
    @key = current_user.keys.new(key_params)

    if @key.save
      redirect_to profile_key_path(@key)
    else
      @keys = current_user.keys.select(&:persisted?)
      render :index
    end
  end

  def destroy
    @key = current_user.keys.find(params[:id])
    @key.destroy unless @key.is_a? LDAPKey

    respond_to do |format|
      format.html { redirect_to profile_keys_url }
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
          render_404 and return
        end
      rescue => e
        render text: e.message
      end
    else
      render_404 and return
    end
  end

  private

  def key_params
    params.require(:key).permit(:title, :key)
  end
end
