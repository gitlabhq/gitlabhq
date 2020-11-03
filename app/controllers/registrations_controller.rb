# frozen_string_literal: true

class RegistrationsController < Devise::RegistrationsController
  include Recaptcha::Verify
  include AcceptsPendingInvitations
  include RecaptchaExperimentHelper
  include InvisibleCaptchaOnSignup

  BLOCKED_PENDING_APPROVAL_STATE = 'blocked_pending_approval'.freeze

  layout :choose_layout

  skip_before_action :required_signup_info, :check_two_factor_requirement, only: [:welcome, :update_registration]
  prepend_before_action :check_captcha, only: :create
  before_action :whitelist_query_limiting, :ensure_destroy_prerequisites_met, only: [:destroy]
  before_action :load_recaptcha, only: :new
  before_action :set_invite_params, only: :new

  feature_category :authentication_and_authorization

  def new
    @resource = build_resource
  end

  def create
    set_user_state
    accept_pending_invitations

    super do |new_user|
      persist_accepted_terms_if_required(new_user)
      set_role_required(new_user)
      yield new_user if block_given?
    end

    # Devise sets a flash message on both successful & failed signups,
    # but we only want to show a message if the resource is blocked by a pending approval.
    flash[:notice] = nil unless resource.blocked_pending_approval?
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
    return redirect_to new_user_registration_path unless current_user

    result = ::Users::SignupService.new(current_user, update_registration_params).execute

    if result[:status] == :success
      if ::Gitlab.com? && show_onboarding_issues_experiment?
        track_experiment_event(:onboarding_issues, 'signed_up')
        record_experiment_user(:onboarding_issues)
      end

      return redirect_to new_users_sign_up_group_path if experiment_enabled?(:onboarding_issues) && show_onboarding_issues_experiment?

      redirect_to path_for_signed_in_user(current_user)
    else
      render :welcome
    end
  end

  protected

  def persist_accepted_terms_if_required(new_user)
    return unless new_user.persisted?
    return unless Gitlab::CurrentSettings.current_application_settings.enforce_terms?

    terms = ApplicationSetting::Term.latest
    Users::RespondToTermsService.new(new_user, terms).execute(accepted: true)
  end

  def set_role_required(new_user)
    new_user.set_role_required! if new_user.persisted?
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

    users_sign_up_welcome_path
  end

  def after_inactive_sign_up_path_for(resource)
    Gitlab::AppLogger.info(user_created_message)
    return new_user_session_path(anchor: 'login-pane') if resource.blocked_pending_approval?

    Feature.enabled?(:soft_email_confirmation) ? dashboard_projects_path : users_almost_there_path
  end

  private

  def ensure_destroy_prerequisites_met
    if current_user.solo_owned_groups.present?
      redirect_to profile_account_path,
        status: :see_other,
        alert: s_('Profiles|You must transfer ownership or delete groups you are an owner of before you can delete your account')
    end
  end

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

    return unless show_recaptcha_sign_up?
    return unless Gitlab::Recaptcha.load_configurations!

    return if verify_recaptcha

    flash[:alert] = _('There was an error with the reCAPTCHA. Please solve the reCAPTCHA again.')
    flash.delete :recaptcha_error
    render action: 'new'
  end

  def sign_up_params
    params.require(:user).permit(:username, :email, :name, :first_name, :last_name, :password)
  end

  def update_registration_params
    params.require(:user).permit(:role, :setup_for_company)
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
    if %w(welcome update_registration).include?(action_name)
      'welcome'
    else
      'devise'
    end
  end

  def show_onboarding_issues_experiment?
    !helpers.in_subscription_flow? &&
      !helpers.in_invitation_flow? &&
      !helpers.in_oauth_flow? &&
      !helpers.in_trial_flow?
  end

  def set_user_state
    return unless Gitlab::CurrentSettings.require_admin_approval_after_user_signup

    resource.state = BLOCKED_PENDING_APPROVAL_STATE
  end

  def set_invite_params
    @invite_email = ActionController::Base.helpers.sanitize(params[:invite_email])
  end
end

RegistrationsController.prepend_if_ee('EE::RegistrationsController')
