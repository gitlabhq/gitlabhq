class Profiles::AccountsController < Profiles::ApplicationController
  include AuthHelper

  def show
    @user = current_user
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def unlink
    provider = params[:provider]
    identity = current_user.identities.find_by(provider: provider)

    return render_404 unless identity

    if unlink_allowed?(provider)
      identity.destroy
    else
      flash[:alert] = "You are not allowed to unlink your primary login account"
    end

    redirect_to profile_account_path
  end
  # rubocop: enable CodeReuse/ActiveRecord
end
