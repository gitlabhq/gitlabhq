class RegistrationsController < Devise::RegistrationsController
  before_action :signup_enabled?
  include Recaptcha::Verify

  def new
    redirect_to(new_user_session_path)
  end

  def create
    if !Gitlab::Recaptcha.load_configurations! || verify_recaptcha
      super
    else
      flash[:alert] = "There was an error with the reCAPTCHA code below. Please re-enter the code."
      flash.delete :recaptcha_error
      render action: 'new'
    end
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

  def resource_name
    :user
  end

  def resource
    @resource ||= User.new(sign_up_params)
  end

  def devise_mapping
    @devise_mapping ||= Devise.mappings[:user]
  end
end
