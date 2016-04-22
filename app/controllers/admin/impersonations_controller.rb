class Admin::ImpersonationsController < Admin::ApplicationController
  skip_before_action :authenticate_admin!
  before_action :authenticate_impersonator!

  def destroy
    redirect_path = admin_user_path(current_user)

    warden.set_user(impersonator, scope: :user)

    session[:impersonator_id] = nil

    redirect_to redirect_path
  end

  private

  def user
    @user ||= User.find(params[:id])
  end

  def impersonator
    @impersonator ||= User.find(session[:impersonator_id]) if session[:impersonator_id]
  end

  def authenticate_impersonator!
    render_404 unless impersonator && impersonator.is_admin? && !impersonator.blocked?
  end
end
