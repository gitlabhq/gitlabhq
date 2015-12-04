class Admin::ImpersonationController < Admin::ApplicationController
  skip_before_action :authenticate_admin!, only: :destroy

  before_action :user
  before_action :authorize_impersonator!

  def create
    if @user.blocked?
      flash[:alert] = "You cannot impersonate a blocked user"

      redirect_to admin_user_path(@user)
    else
      session[:impersonator_id] = current_user.username
      session[:impersonator_return_to] = admin_user_path(@user)

      warden.set_user(user, scope: 'user')

      flash[:alert] = "You are impersonating #{user.username}."

      redirect_to root_path
    end
  end

  def destroy
    redirect = session[:impersonator_return_to]

    warden.set_user(user, scope: 'user')

    session[:impersonator_return_to] = nil
    session[:impersonator_id] = nil

    redirect_to redirect || root_path
  end

  def user
    @user ||= User.find_by!(username: params[:id] || session[:impersonator_id])
  end
end
