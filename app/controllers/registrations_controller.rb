class RegistrationsController < Devise::RegistrationsController
  before_action :signup_enabled?

  def new
    redirect_to(new_user_session_path)
  end

  def destroy
    DeleteUserService.new(current_user).execute(current_user)

    respond_to do |format|
      format.html { redirect_to new_user_session_path, notice: "Account successfully removed." }
    end
  end

  protected

  def build_resource(hash=nil)
    super
  end

  def after_sign_up_path_for(_resource)
    new_user_session_path
  end

  def after_inactive_sign_up_path_for(_resource)
    new_user_session_path
  end

  private

  def signup_enabled?
    unless current_application_settings.signup_enabled?
      redirect_to(new_user_session_path)
    end
  end

  def sign_up_params
    params.require(:user).permit(:username, :email, :name, :password, :password_confirmation)
  end
end
