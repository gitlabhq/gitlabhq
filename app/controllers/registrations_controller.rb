# frozen_string_literal: true

class RegistrationsController < Devise::RegistrationsController
  include Recaptcha::Verify
  include AcceptsPendingInvitations
  include RecaptchaExperimentHelper

  prepend_before_action :check_captcha, only: :create
  before_action :whitelist_query_limiting, only: [:destroy]
  before_action :ensure_terms_accepted,
    if: -> { action_name == 'create' && Gitlab::CurrentSettings.current_application_settings.enforce_terms? }

  def new
    redirect_to(new_user_session_path)
  end

  def create
    accept_pending_invitations

    super do |new_user|
      persist_accepted_terms_if_required(new_user)
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

  def persist_accepted_terms_if_required(new_user)
    return unless new_user.persisted?
    return unless Gitlab::CurrentSettings.current_application_settings.enforce_terms?

    if terms_accepted?
      terms = ApplicationSetting::Term.latest
      Users::RespondToTermsService.new(new_user, terms).execute(accepted: true)
    end
  end

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
    Gitlab::AppLogger.info(user_created_message(confirmed: user.confirmed?))
    user.confirmed? || Feature.enabled?(:soft_email_confirmation) ? stored_location_for(user) || dashboard_projects_path : users_almost_there_path
  end

  def after_inactive_sign_up_path_for(resource)
    Gitlab::AppLogger.info(user_created_message)
    Feature.enabled?(:soft_email_confirmation) ? dashboard_projects_path : users_almost_there_path
  end

  private

  def user_created_message(confirmed: false)
    "User Created: username=#{resource.username} email=#{resource.email} ip=#{request.remote_ip} confirmed:#{confirmed}"
  end

  def ensure_correct_params!
    # To avoid duplicate form fields on the login page, the registration form
    # names fields using `new_user`, but Devise still wants the params in
    # `user`.
    if params["new_#{resource_name}"].present? && params[resource_name].blank?
      params[resource_name] = params.delete(:"new_#{resource_name}")
    end
  end

  def check_captcha
    ensure_correct_params!

    return unless Feature.enabled?(:registrations_recaptcha, default_enabled: true) # reCAPTCHA on the UI will still display however
    return unless show_recaptcha_sign_up?
    return unless Gitlab::Recaptcha.load_configurations!

    return if verify_recaptcha

    flash[:alert] = _('There was an error with the reCAPTCHA. Please solve the reCAPTCHA again.')
    flash.delete :recaptcha_error
    render action: 'new'
  end

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

  def ensure_terms_accepted
    return if terms_accepted?

    redirect_to new_user_session_path, alert: _('You must accept our Terms of Service and privacy policy in order to register an account')
  end

  def terms_accepted?
    Gitlab::Utils.to_boolean(params[:terms_opt_in])
  end
end
