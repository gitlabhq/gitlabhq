class RegistrationsController < Devise::RegistrationsController
  include Recaptcha::Verify

  before_action :whitelist_query_limiting, only: [:destroy]

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
    if destroy_confirmation_valid?
      current_user.delete_async(deleted_by: current_user)
      session.try(:destroy)
      redirect_to new_user_session_path, status: 303, notice: s_('Profiles|Account scheduled for removal.')
    else
      redirect_to profile_account_path, status: 303, alert: destroy_confirmation_failure_message
    end
  end

  protected

  def destroy_confirmation_valid?
    if current_user.confirm_deletion_with_password?
      current_user.valid_password?(params[:password])
    else
      current_user.username == params[:username]
    end
  end

  def destroy_confirmation_failure_message
    if current_user.confirm_deletion_with_password?
      s_('Profiles|Invalid password')
    else
      s_('Profiles|Invalid username')
    end
  end

  def build_resource(hash = nil)
    super
  end

  def after_sign_up_path_for(user)
    Gitlab::AppLogger.info("User Created: username=#{user.username} email=#{user.email} ip=#{request.remote_ip} confirmed:#{user.confirmed?}")
    user.confirmed? ? dashboard_projects_path : users_almost_there_path
  end

  def after_inactive_sign_up_path_for(resource)
    Gitlab::AppLogger.info("User Created: username=#{resource.username} email=#{resource.email} ip=#{request.remote_ip} confirmed:false")
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

  def whitelist_query_limiting
    Gitlab::QueryLimiting.whitelist('https://gitlab.com/gitlab-org/gitlab-ce/issues/42380')
  end
end
