class Profiles::PersonalAccessTokensController < Profiles::ApplicationController
  def index
    @user = current_user

    # Prefer this to `@user.personal_access_tokens.new`, because it
    # litters the view's call to `@user.personal_access_tokens` with
    # this stub personal access token.
    @personal_access_token = PersonalAccessToken.new(user: @user)
  end

  def create
    @personal_access_token = current_user.personal_access_tokens.generate(personal_access_token_params)

    if @personal_access_token.save
      redirect_to profile_personal_access_tokens_path, notice: "Created personal access token!"
    else
      render :index
    end
  end

  def revoke
    @personal_access_token = current_user.personal_access_tokens.find(params[:id])

    if @personal_access_token.revoke!
      redirect_to profile_personal_access_tokens_path, notice: "Revoked personal access token #{@personal_access_token.name}!"
    else
      render :index
    end
  end

  private

  def personal_access_token_params
    params.require(:personal_access_token).permit(:name, :expires_at)
  end
end
