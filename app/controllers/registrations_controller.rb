# frozen_string_literal: true

class RegistrationsController < Devise::RegistrationsController
  include Recaptcha::Verify
  include AcceptsPendingInvitations
  include RecaptchaHelper
  include InvisibleCaptchaOnSignup
  include OneTrustCSP
  include BizibleCSP
  include GoogleAnalyticsCSP

  layout 'devise'

  prepend_before_action :check_captcha, only: :create
  before_action :ensure_destroy_prerequisites_met, only: [:destroy]
  before_action :load_recaptcha, only: :new
  before_action :set_invite_params, only: :new
  before_action only: [:create] do
    check_rate_limit!(:user_sign_up, scope: request.ip)
  end

  before_action only: [:new] do
    push_frontend_feature_flag(:gitlab_gtm_datalayer, type: :ops)
  end

  feature_category :authentication_and_authorization

  def new
    @resource = build_resource
  end

  def create
    set_user_state

    super do |new_user|
      accept_pending_invitations if new_user.persisted?

      persist_accepted_terms_if_required(new_user)
      set_role_required(new_user)
      track_experiment_event(new_user)

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

  def after_request_hook(user)
    # overridden by EE module
  end

  def after_sign_up_path_for(user)
    Gitlab::AppLogger.info(user_created_message(confirmed: user.confirmed?))

    users_sign_up_welcome_path
  end

  def after_inactive_sign_up_path_for(resource)
    Gitlab::AppLogger.info(user_created_message)
    return new_user_session_path(anchor: 'login-pane') if resource.blocked_pending_approval?

    Feature.enabled?(:soft_email_confirmation) ? dashboard_projects_path : users_almost_there_path(email: resource.email)
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
    add_gon_variables
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
                    .new(current_user, sign_up_params.merge({ skip_confirmation: skip_email_confirmation? }))
                    .execute
  end

  def devise_mapping
    @devise_mapping ||= Devise.mappings[:user]
  end

  def skip_email_confirmation?
    invite_email = session.delete(:invite_email)

    sign_up_params[:email] == invite_email
  end

  def load_recaptcha
    Gitlab::Recaptcha.load_configurations!
  end

  def set_user_state
    return unless set_blocked_pending_approval?

    resource.state = User::BLOCKED_PENDING_APPROVAL_STATE
  end

  def set_blocked_pending_approval?
    Gitlab::CurrentSettings.require_admin_approval_after_user_signup
  end

  def set_invite_params
    @invite_email = ActionController::Base.helpers.sanitize(params[:invite_email])
  end

  def after_pending_invitations_hook
    member_id = session.delete(:originating_member_id)

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

  def track_experiment_event(new_user)
    # Track signed up event to relate it with click "Sign up" button events from
    # the experimental logged out header with marketing links. This allows us to
    # have a funnel of visitors clicking on the header and those visitors
    # signing up and becoming users
    experiment(:logged_out_marketing_header, actor: new_user).track(:signed_up) if new_user.persisted?
  end
end

RegistrationsController.prepend_mod_with('RegistrationsController')
