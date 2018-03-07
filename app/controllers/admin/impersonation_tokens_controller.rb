class Admin::ImpersonationTokensController < Admin::ApplicationController
  before_action :user

  def index
    set_index_vars
  end

  def create
    @impersonation_token = finder.build(impersonation_token_params)

    if @impersonation_token.save
      redirect_to admin_user_impersonation_tokens_path, notice: "A new impersonation token has been created."
    else
      set_index_vars
      render :index
    end
  end

  def revoke
    @impersonation_token = finder.find(params[:id])

    if @impersonation_token.revoke!
      flash[:notice] = "Revoked impersonation token #{@impersonation_token.name}!"
    else
      flash[:alert] = "Could not revoke impersonation token #{@impersonation_token.name}."
    end

    redirect_to admin_user_impersonation_tokens_path
  end

  private

  def user
    @user ||= User.find_by!(username: params[:user_id])
  end

  def finder(options = {})
    PersonalAccessTokensFinder.new({ user: user, impersonation: true }.merge(options))
  end

  def impersonation_token_params
    params.require(:personal_access_token).permit(:name, :expires_at, :impersonation, scopes: [])
  end

  def set_index_vars
    @scopes = Gitlab::Auth.available_scopes(current_user)

    @impersonation_token ||= finder.build
    @inactive_impersonation_tokens = finder(state: 'inactive').execute
    @active_impersonation_tokens = finder(state: 'active').execute.order(:expires_at)
  end
end
