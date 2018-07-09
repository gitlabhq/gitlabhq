class Admin::ImpersonationsController < Admin::ApplicationController
  skip_before_action :authenticate_admin!
  before_action :authenticate_impersonator!

  def destroy
    original_user = current_user

    warden.set_user(impersonator, scope: :user)

    Gitlab::AppLogger.info("User #{impersonator.username} has stopped impersonating #{original_user.username}")

    session[:impersonator_id] = nil

    redirect_to admin_user_path(original_user), status: :found
  end

  private

  def impersonator
    @impersonator ||= User.find(session[:impersonator_id]) if session[:impersonator_id]
  end

  def authenticate_impersonator!
    render_404 unless impersonator && impersonator.admin? && !impersonator.blocked?
  end
end
