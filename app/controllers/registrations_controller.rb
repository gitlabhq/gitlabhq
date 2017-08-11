class RegistrationsController < Devise::RegistrationsController
  include Recaptcha::Verify
  prepend EE::RegistrationsController

  def new
    redirect_to(new_user_session_path)
  end

  def create
    # To avoid duplicate form fields on the login page, the registration form
    # names fields using `new_user`, but Devise still wants the params in
    # `user`.
    if params["new_#{resource_name}"].present? && params[resource_name].blank?
      params[resource_name] = params.delete(:"new_#{resource_name}")
    end

    if !Gitlab::Recaptcha.load_configurations! || verify_recaptcha
      super
    else
      flash[:alert] = 'There was an error with the reCAPTCHA. Please solve the reCAPTCHA again.'
      flash.delete :recaptcha_error
      render action: 'new'
    end
  rescue Gitlab::Access::AccessDeniedError
    redirect_to(new_user_session_path)
  end

  def destroy
    current_user.delete_async(deleted_by: current_user)

    respond_to do |format|
      format.html do
        session.try(:destroy)
        redirect_to new_user_session_path, status: 302, notice: "Account scheduled for removal."
      end
    end
  end

  protected

  def build_resource(hash = nil)
    super
  end

  def after_sign_up_path_for(user)
    user.confirmed? ? dashboard_projects_path : users_almost_there_path
  end

  def after_inactive_sign_up_path_for(_resource)
    users_almost_there_path
  end

  private

  def sign_up_params
    params.require(:user).permit(:username, :email, :email_confirmation, :name, :password)
  end

  def resource_name
    :user
  end

  def resource
    @resource ||= Users::BuildService.new(current_user, sign_up_params).execute
  end

  def devise_mapping
    @devise_mapping ||= Devise.mappings[:user]
  end
end
