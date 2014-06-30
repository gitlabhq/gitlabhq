class Profiles::PasswordsController < ApplicationController
  layout :determine_layout

  skip_before_filter :check_password_expiration, only: [:new, :create]

  before_filter :set_user
  before_filter :set_title
  before_filter :authorize_change_password!

  def new
  end

  def create
    new_password = user_params[:password]
    new_password_confirmation = user_params[:password_confirmation]

    result = @user.update_attributes(
      password: new_password,
      password_confirmation: new_password_confirmation
    )

    if result
      @user.update_attributes(password_expires_at: nil)
      redirect_to root_path, notice: 'Password successfully changed'
    else
      render :new
    end
  end

  def edit
  end

  def update
    password_attributes = user_params.select do |key, value|
      %w(password password_confirmation).include?(key.to_s)
    end

    unless @user.valid_password?(user_params[:current_password])
      redirect_to edit_profile_password_path, alert: 'You must provide a valid current password'
      return
    end

    if @user.update_attributes(password_attributes)
      flash[:notice] = "Password was successfully updated. Please login with it"
      redirect_to new_user_session_path
    else
      render 'edit'
    end
  end

  def reset
    current_user.send_reset_password_instructions
    redirect_to edit_profile_password_path, notice: 'We sent you an email with reset password instructions'
  end

  private

  def set_user
    @user = current_user
  end

  def set_title
    @title = "New password"
  end

  def determine_layout
    if [:new, :create].include?(action_name.to_sym)
      'navless'
    else
      'profile'
    end
  end

  def authorize_change_password!
    return render_404 if @user.ldap_user?
  end

  def user_params
    params.require(:user).permit(:current_password, :password, :password_confirmation)
  end
end
