class Profiles::AccountsController < Profiles::ApplicationController
  def show
    @user = current_user
  end

  def unlink
    provider = params[:provider]
    current_user.identities.find_by(provider: provider).destroy
    redirect_to profile_account_path
  end
end
