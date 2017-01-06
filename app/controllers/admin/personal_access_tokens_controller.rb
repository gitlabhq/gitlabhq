class Admin::PersonalAccessTokensController < Admin::ApplicationController
  before_action :user

  def index
    set_index_vars
  end

  def create
    @personal_access_token = user.personal_access_tokens.generate(personal_access_token_params)

    if @personal_access_token.save
      flash[:personal_access_token] = @personal_access_token.token
      redirect_to admin_user_personal_access_tokens_path, notice: "A new personal access token has been created."
    else
      set_index_vars
      render :index
    end
  end

  def revoke
    @personal_access_token = user.personal_access_tokens.find(params[:id])

    if @personal_access_token.revoke!
      flash[:notice] = "Revoked personal access token #{@personal_access_token.name}!"
    else
      flash[:alert] = "Could not revoke personal access token #{@personal_access_token.name}."
    end

    redirect_to admin_user_personal_access_tokens_path
  end

  private

  def user
    @user ||= User.find_by!(username: params[:user_id])
  end

  def personal_access_token_params
    params.require(:personal_access_token).permit(:name, :expires_at, :impersonation, scopes: [])
  end

  def set_index_vars
    @personal_access_token ||= user.personal_access_tokens.build
    @scopes = Gitlab::Auth::SCOPES
    @active_personal_access_tokens = PersonalAccessToken.and_impersonation_tokens.where(user_id: user.id).active.order(:expires_at)
    @inactive_personal_access_tokens = PersonalAccessToken.and_impersonation_tokens.where(user_id: user.id).inactive
  end
end
