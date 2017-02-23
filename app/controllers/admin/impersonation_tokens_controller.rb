class Admin::ImpersonationTokensController < Admin::ApplicationController
  before_action :user

  def index
    set_index_vars
  end

  def create
    # We never want to non-impersonate a user
    @impersonation_token = user.personal_access_tokens.build(impersonation_token_params.merge(impersonation: true))

    if @impersonation_token.save
      flash[:impersonation_token] = @impersonation_token.token
      redirect_to admin_user_impersonation_tokens_path, notice: "A new impersonation token has been created."
    else
      set_index_vars
      render :index
    end
  end

  def revoke
    @impersonation_token = user.personal_access_tokens.impersonation.find(params[:id])

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

  def impersonation_token_params
    params.require(:personal_access_token).permit(:name, :expires_at, :impersonation, scopes: [])
  end

  def set_index_vars
    @impersonation_token ||= user.personal_access_tokens.build
    @scopes = Gitlab::Auth::SCOPES
    @active_impersonation_tokens = user.personal_access_tokens.impersonation.active.order(:expires_at)
    @inactive_impersonation_tokens = user.personal_access_tokens.impersonation.inactive
  end
end
