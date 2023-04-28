# frozen_string_literal: true

class RegistrationsController < Devise::RegistrationsController
  include Recaptcha::Adapters::ControllerMethods
  include AcceptsPendingInvitations
  include RecaptchaHelper
  include InvisibleCaptchaOnSignup
  include OneTrustCSP
  include BizibleCSP
  include GoogleAnalyticsCSP
  include PreferredLanguageSwitcher
  include RegistrationsTracking
  include Gitlab::Tracking::Helpers::WeakPasswordErrorEvent

  layout 'devise'

  prepend_before_action :check_captcha, only: :create
  before_action :ensure_first_name_and_last_name_not_empty, only: :create
  before_action :ensure_destroy_prerequisites_met, only: [:destroy]
  before_action :init_preferred_language, only: :new
  before_action :load_recaptcha, only: :new
  before_action only: [:create] do
    check_rate_limit!(:user_sign_up, scope: request.ip)
  end

  before_action only: [:new] do
    push_frontend_feature_flag(:gitlab_gtm_datalayer, type: :ops)
  end

  feature_category :user_management

  helper_method :arkose_labs_enabled?

  def new
    @resource = build_resource
    set_invite_params
  end

  def create
    set_resource_fields

    super do |new_user|
      record_arkose_data
      accept_pending_invitations if new_user.persisted?

      persist_accepted_terms_if_required(new_user)
      set_role_required(new_user)
      send_custom_confirmation_instructions
      track_weak_password_error(new_user, self.class.name, 'create')

      if pending_approval?
        NotificationService.new.new_instance_access_request(new_user)
      end

      after_request_hook(new_user)

      yield new_user if block_given?
    end

    # Devise sets a flash message on both successful & failed signups,
    # but we only want to show a message if the resource is blocked by a pending approval.
    flash[:notice] = nil unless resource.blocked_pending_approval?
  rescue Gitlab::Access::AccessDeniedError
    redirect_to(new_user_session_path)
  end

  def destroy
    if current_user.required_terms_not_accepted?
      redirect_to profile_account_path, status: :see_other, alert: s_('Profiles|You must accept the Terms of Service in order to perform this action.')
      return
    end

    if destroy_confirmation_valid?
      current_user.delete_async(deleted_by: current_user)
      session.try(:destroy)
      redirect_to new_user_session_path, status: :see_other, notice: s_('Profiles|Account scheduled for removal.')
    else
      redirect_to profile_account_path, status: :see_other, alert: destroy_confirmation_failure_message
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

  # overridden by EE module
  def after_request_hook(user)
    return unless user.persisted?

    track_creation user: user
    Gitlab::Tracking.event(self.class.name, 'successfully_submitted_form', user: user)
  end

  def after_sign_up_path_for(user)
    Gitlab::AppLogger.info(user_created_message(confirmed: user.confirmed?))

    after_sign_up_path
  end

  def after_inactive_sign_up_path_for(resource)
    Gitlab::AppLogger.info(user_created_message)
    return new_user_session_path(anchor: 'login-pane') if resource.blocked_pending_approval?
    return dashboard_projects_path if Gitlab::CurrentSettings.email_confirmation_setting_soft?

    # when email_confirmation_setting is set to `hard`, path to redirect is saved
    # after user confirms and comes back, he will be redirected
    store_location_for(:redirect, after_sign_up_path)

    if identity_verification_enabled?
      session[:verification_user_id] = resource.id # This is needed to find the user on the identity verification page
      User.sticking.stick_or_unstick_request(request.env, :user, resource.id)

      return identity_verification_redirect_path
    end

    Gitlab::Tracking.event(self.class.name, 'render', user: resource)
    users_almost_there_path(email: resource.email)
  end

  private

  def after_sign_up_path
    users_sign_up_welcome_path(glm_tracking_params)
  end

  def track_creation(user:)
    label = user_invited? ? 'invited' : 'signup'
    Gitlab::Tracking.event(self.class.name, 'create_user', label: label, user: user)
  end

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
    add_gon_variables
    set_minimum_password_length
    render action: 'new'
  end

  def ensure_first_name_and_last_name_not_empty
    # The key here will be affected by feature flag 'arkose_labs_signup_challenge'
    # When flag is disabled, the key will be 'user' because #check_captcha will remove 'new_' prefix
    # When flag is enabled, #check_captcha will be skipped, so the key will have 'new_' prefix
    first_name = params.dig(resource_name, :first_name) || params.dig("new_#{resource_name}", :first_name)
    last_name = params.dig(resource_name, :last_name) || params.dig("new_#{resource_name}", :last_name)

    return if first_name.present? && last_name.present?

    resource.errors.add(_('First name'), _("cannot be blank")) if first_name.blank?
    resource.errors.add(_('Last name'), _("cannot be blank")) if last_name.blank?

    render action: 'new'
  end

  def pending_approval?
    return false unless Gitlab::CurrentSettings.require_admin_approval_after_user_signup

    resource.persisted? && resource.blocked_pending_approval?
  end

  def sign_up_params_attributes
    [:username, :email, :name, :first_name, :last_name, :password]
  end

  def sign_up_params
    params.require(:user).permit(sign_up_params_attributes)
  end

  def resource_name
    :user
  end

  def resource
    @resource ||= Users::RegistrationsBuildService
                    .new(current_user, sign_up_params.merge({ skip_confirmation: skip_confirmation?,
                                                              preferred_language: preferred_language }))
                    .execute
  end

  def devise_mapping
    @devise_mapping ||= Devise.mappings[:user]
  end

  def skip_confirmation?
    registered_with_invite_email?
  end

  def registered_with_invite_email?
    invite_email = session.delete(:invite_email)

    sign_up_params[:email] == invite_email
  end

  def load_recaptcha
    Gitlab::Recaptcha.load_configurations!
  end

  # overridden by EE module
  def set_resource_fields
    return unless set_blocked_pending_approval?

    resource.state = User::BLOCKED_PENDING_APPROVAL_STATE
  end

  # overridden by EE module
  def set_blocked_pending_approval?
    Gitlab::CurrentSettings.require_admin_approval_after_user_signup
  end

  def set_invite_params
    if resource.email.blank? && params[:invite_email].present?
      resource.email = @invite_email = ActionController::Base.helpers.sanitize(params[:invite_email])
    end
  end

  def user_invited?
    !!member_id
  end

  def member_id
    @member_id ||= session.delete(:originating_member_id)
  end

  def after_pending_invitations_hook
    return unless member_id

    # if invited multiple times to different projects, only the email clicked will be counted as accepted
    # for the specific member on a project or group
    member = resource.members.find_by(id: member_id) # rubocop: disable CodeReuse/ActiveRecord

    return unless member

    Gitlab::Tracking.event(self.class.name, 'accepted', label: 'invite_email', property: member.id.to_s, user: resource)
  end

  def context_user
    current_user
  end

  def record_arkose_data
    # overridden by EE module
  end

  def identity_verification_enabled?
    # overridden by EE module
    false
  end

  def identity_verification_redirect_path
    # overridden by EE module
  end

  def send_custom_confirmation_instructions
    # overridden by EE module
  end

  def arkose_labs_enabled?
    false
  end
end

RegistrationsController.prepend_mod_with('RegistrationsController')
