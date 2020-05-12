# frozen_string_literal: true

class RegistrationsController < Devise::RegistrationsController
  include Recaptcha::Verify
  include AcceptsPendingInvitations
  include RecaptchaExperimentHelper
  include InvisibleCaptchaOnSignup

  layout :choose_layout

  skip_before_action :required_signup_info, :check_two_factor_requirement, only: [:welcome, :update_registration]
  prepend_before_action :check_captcha, only: :create
  before_action :whitelist_query_limiting, only: [:destroy]
  before_action :ensure_terms_accepted,
    if: -> { action_name == 'create' && Gitlab::CurrentSettings.current_application_settings.enforce_terms? }
  before_action :load_recaptcha, only: :new

  def new
    if experiment_enabled?(:signup_flow)
      track_experiment_event(:signup_flow, 'start') # We want this event to be tracked when the user is _in_ the experimental group
      @resource = build_resource
    else
      redirect_to new_user_session_path(anchor: 'register-pane')
    end
  end

  def create
    track_experiment_event(:signup_flow, 'end') unless experiment_enabled?(:signup_flow) # We want this event to be tracked when the user is _in_ the control group

    accept_pending_invitations

    super do |new_user|
      persist_accepted_terms_if_required(new_user)
      set_role_required(new_user)
      yield new_user if block_given?
    end

    # Do not show the signed_up notice message when the signup_flow experiment is enabled.
    # Instead, show it after successfully updating the role.
    flash[:notice] = nil if experiment_enabled?(:signup_flow)
  rescue Gitlab::Access::AccessDeniedError
    redirect_to(new_user_session_path)
  end

  def destroy
    if destroy_confirmation_valid?
      current_user.delete_async(deleted_by: current_user)
      session.try(:destroy)
      redirect_to new_user_session_path, status: :see_other, notice: s_('Profiles|Account scheduled for removal.')
    else
      redirect_to profile_account_path, status: :see_other, alert: destroy_confirmation_failure_message
    end
  end

  def welcome
    return redirect_to new_user_registration_path unless current_user
    return redirect_to path_for_signed_in_user(current_user) if current_user.role.present? && !current_user.setup_for_company.nil?
  end

  def update_registration
    user_params = params.require(:user).permit(:role, :setup_for_company)
    result = ::Users::SignupService.new(current_user, user_params).execute

    if result[:status] == :success
      track_experiment_event(:signup_flow, 'end') # We want this event to be tracked when the user is _in_ the experimental group
      set_flash_message! :notice, :signed_up
      redirect_to path_for_signed_in_user(current_user)
    else
      render :welcome
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

  def set_role_required(new_user)
    new_user.set_role_required! if new_user.persisted? && experiment_enabled?(:signup_flow)
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

    return users_sign_up_welcome_path if experiment_enabled?(:signup_flow)

    path_for_signed_in_user(user)
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
    params.require(:user).permit(:username, :email, :email_confirmation, :name, :first_name, :last_name, :password)
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
    Gitlab::QueryLimiting.whitelist('https://gitlab.com/gitlab-org/gitlab-foss/issues/42380')
  end

  def ensure_terms_accepted
    return if terms_accepted?

    redirect_to new_user_session_path, alert: _('You must accept our Terms of Service and privacy policy in order to register an account')
  end

  def terms_accepted?
    Gitlab::Utils.to_boolean(params[:terms_opt_in])
  end

  def path_for_signed_in_user(user)
    if requires_confirmation?(user)
      users_almost_there_path
    else
      stored_location_for(user) || dashboard_projects_path
    end
  end

  def requires_confirmation?(user)
    return false if user.confirmed?
    return false if Feature.enabled?(:soft_email_confirmation)
    return false if experiment_enabled?(:signup_flow)

    true
  end

  def load_recaptcha
    Gitlab::Recaptcha.load_configurations!
  end

  # Part of an experiment to build a new sign up flow. Will be resolved
  # with https://gitlab.com/gitlab-org/growth/engineering/issues/64
  def choose_layout
    if experiment_enabled?(:signup_flow)
      'devise_experimental_separate_sign_up_flow'
    else
      'devise'
    end
  end
end

RegistrationsController.prepend_if_ee('EE::RegistrationsController')
