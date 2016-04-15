class Profiles::PersonalAccessTokensController < ApplicationController
  def index
    @user = current_user
    @personal_access_token = current_user.personal_access_tokens.new
  end

  def create
    @personal_access_token = current_user.personal_access_tokens.generate(personal_access_token_params)

    if @personal_access_token.save
      redirect_to profile_personal_access_tokens_path, notice: "Created personal access token!"
    else
      render :index
    end
  end

  private

  def personal_access_token_params
    params.require(:personal_access_token).permit(:name)
  end
end
