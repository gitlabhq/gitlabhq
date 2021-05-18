# frozen_string_literal: true

class SessionsController < Devise::SessionsController
  include InternalRedirect
  include AuthenticatesWithTwoFactor
  include Devise::Controllers::Rememberable
  include Recaptcha::ClientHelper
  include Recaptcha::Verify
  include RendersLdapServers
  include KnownSignIn
  include Gitlab::Utils::StrongMemoize

  skip_before_action :check_two_factor_requirement, only: [:destroy]
  skip_before_action :check_password_expiration, only: [:destroy]

  # replaced with :require_no_authentication_without_flash
  skip_before_action :require_no_authentication, only: [:new, :create]

  prepend_before_action :check_initial_setup, only: [:new]
  prepend_before_action :authenticate_with_two_factor,
    if: -> { action_name == 'create' && two_factor_enabled? }
  prepend_before_action :check_captcha, only: [:create]
  prepend_before_action :store_redirect_uri, only: [:new]
  prepend_before_action :require_no_authentication_without_flash, only: [:new, :create]
  prepend_before_action :check_forbidden_password_based_login, if: -> { action_name == 'create' && password_based_login? }
  prepend_before_action :ensure_password_authentication_enabled!, if: -> { action_name == 'create' && password_based_login? }

  before_action :auto_sign_in_with_provider, only: [:new]
  before_action :store_unauthenticated_sessions, only: [:new]
  before_action :save_failed_login, if: :action_new_and_failed_login?
  before_action :load_recaptcha
  before_action :set_invite_params, only: [:new]
  before_action do
    push_frontend_feature_flag(:webauthn)
  end

  after_action :log_failed_login, if: :action_new_and_failed_login?
  after_action :verify_known_sign_in, only: [:create]

  helper_method :captcha_enabled?, :captcha_on_login_required?

  # protect_from_forgery is already prepended in ApplicationController but
  # authenticate_with_two_factor which signs in the user is prepended before
  # that here.
  # We need to make sure CSRF token is verified before authenticating the user
  # because Devise.clean_up_csrf_token_on_authentication is set to true by
  # default to avoid CSRF token fixation attacks. Authenticating the user first
  # would cause the CSRF token to be cleared and then
  # RequestForgeryProtection#verify_authenticity_token would fail because of
  # token mismatch.
  protect_from_forgery with: :exception, prepend: true, except: :destroy

  feature_category :authentication_and_authorization

  CAPTCHA_HEADER = 'X-GitLab-Show-Login-Captcha'
  MAX_FAILED_LOGIN_ATTEMPTS = 5

  def new
    set_minimum_password_length

    super
  end

  def create
    super do |resource|
      # User has successfully signed in, so clear any unused reset token
      if resource.reset_password_token.present?
        resource.update(reset_password_token: nil,
                        reset_password_sent_at: nil)
      end

      if resource.deactivated?
        resource.activate
        flash[:notice] = _('Welcome back! Your account had been deactivated due to inactivity but is now reactivated.')
      else
        # hide the default signed-in notification
        flash[:notice] = nil
      end

      log_audit_event(current_user, resource, with: authentication_method)
      log_user_activity(current_user)
    end
  end

  def destroy
    Gitlab::AppLogger.info("User Logout: username=#{current_user.username} ip=#{request.remote_ip}")
    super
    # hide the signed_out notice
    flash[:notice] = nil
  end

  private

  def require_no_authentication_without_flash
    require_no_authentication

    if flash[:alert] == I18n.t('devise.failure.already_authenticated')
      flash[:alert] = nil
    end
  end

  def captcha_enabled?
    request.headers[CAPTCHA_HEADER] && Gitlab::Recaptcha.enabled?
  end

  def captcha_on_login_required?
    Gitlab::Recaptcha.enabled_on_login? && unverified_anonymous_user?
  end

  # From https://github.com/plataformatec/devise/wiki/How-To:-Use-Recaptcha-with-Devise#devisepasswordscontroller
  def check_captcha
    return unless user_params[:password].present?
    return unless captcha_enabled? || captcha_on_login_required?
    return unless Gitlab::Recaptcha.load_configurations!

    if verify_recaptcha
      increment_successful_login_captcha_counter
    else
      increment_failed_login_captcha_counter

      self.resource = resource_class.new
      flash[:alert] = _('There was an error with the reCAPTCHA. Please solve the reCAPTCHA again.')
      flash.delete :recaptcha_error

      respond_with_navigational(resource) { render :new }
    end
  end

  def increment_failed_login_captcha_counter
    Gitlab::Metrics.counter(
      :failed_login_captcha_total,
      'Number of failed CAPTCHA attempts for logins'
    ).increment
  end

  def increment_successful_login_captcha_counter
    Gitlab::Metrics.counter(
      :successful_login_captcha_total,
      'Number of successful CAPTCHA attempts for logins'
    ).increment
  end

  ##
  # We do have some duplication between lib/gitlab/auth/activity.rb here, but
  # leaving this method here because of backwards compatibility.
  #
  def login_counter
    @login_counter ||= Gitlab::Metrics.counter(:user_session_logins_total, 'User sign in count')
  end

  def log_failed_login
    Gitlab::AppLogger.info("Failed Login: username=#{user_params[:login]} ip=#{request.remote_ip}")
  end

  def action_new_and_failed_login?
    action_name == 'new' && failed_login?
  end

  def save_failed_login
    session[:failed_login_attempts] ||= 0
    session[:failed_login_attempts] += 1
  end

  def failed_login?
    (options = request.env["warden.options"]) && options[:action] == "unauthenticated"
  end

  # counting sessions per IP lets us check if there are associated multiple
  # anonymous sessions with one IP and prevent situations when there are
  # multiple attempts of logging in
  def store_unauthenticated_sessions
    return if current_user

    Gitlab::AnonymousSession.new(request.remote_ip).count_session_ip
  end

  # Handle an "initial setup" state, where there's only one user, it's an admin,
  # and they require a password change.
  # rubocop: disable CodeReuse/ActiveRecord
  def check_initial_setup
    return unless User.limit(2).count == 1 # Count as much 2 to know if we have exactly one

    user = User.admins.last

    return unless user && user.require_password_creation_for_web?

    Users::UpdateService.new(current_user, user: user).execute do |user|
      @token = user.generate_reset_token
    end

    redirect_to edit_user_password_path(reset_password_token: @token),
      notice: _("Please create a password for your new account.")
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def ensure_password_authentication_enabled!
    render_403 unless Gitlab::CurrentSettings.password_authentication_enabled_for_web?
  end

  def password_based_login?
    user_params[:login].present? || user_params[:password].present?
  end

  def user_params
    params.require(:user).permit(:login, :password, :remember_me, :otp_attempt, :device_response)
  end

  def find_user
    strong_memoize(:find_user) do
      if session[:otp_user_id] && user_params[:login]
        User.by_id_and_login(session[:otp_user_id], user_params[:login]).first
      elsif session[:otp_user_id]
        User.find(session[:otp_user_id])
      elsif user_params[:login]
        User.by_login(user_params[:login])
      end
    end
  end

  def stored_redirect_uri
    @redirect_to ||= stored_location_for(:redirect)
  end

  def store_redirect_uri
    redirect_uri =
      if request.referer.present? && (params['redirect_to_referer'] == 'yes')
        URI(request.referer)
      else
        URI(request.url)
      end

    # Prevent a 'you are already signed in' message directly after signing:
    # we should never redirect to '/users/sign_in' after signing in successfully.
    return true if redirect_uri.path == new_user_session_path

    redirect_to = redirect_uri.to_s if host_allowed?(redirect_uri)

    @redirect_to = redirect_to
    store_location_for(:redirect, redirect_to)
  end

  def two_factor_enabled?
    find_user&.two_factor_enabled?
  end

  def auto_sign_in_with_provider
    return unless Gitlab::Auth.omniauth_enabled?

    provider = Gitlab.config.omniauth.auto_sign_in_with_provider
    return unless provider.present?

    # If a "auto_sign_in" query parameter is set to a falsy value, don't auto sign-in.
    # Otherwise, the default is to auto sign-in.
    return if Gitlab::Utils.to_boolean(params[:auto_sign_in]) == false

    # Auto sign in with an Omniauth provider only if the standard "you need to sign-in" alert is
    # registered or no alert at all. In case of another alert (such as a blocked user), it is safer
    # to do nothing to prevent redirection loops with certain Omniauth providers.
    return unless flash[:alert].blank? || flash[:alert] == I18n.t('devise.failure.unauthenticated')

    # Prevent alert from popping up on the first page shown after authentication.
    flash[:alert] = nil

    redirect_to omniauth_authorize_path(:user, provider)
  end

  def valid_otp_attempt?(user)
    otp_validation_result =
      ::Users::ValidateOtpService.new(user).execute(user_params[:otp_attempt])
    return true if otp_validation_result[:status] == :success

    user.invalidate_otp_backup_code!(user_params[:otp_attempt])
  end

  def log_audit_event(user, resource, options = {})
    Gitlab::AppLogger.info("Successful Login: username=#{resource.username} ip=#{request.remote_ip} method=#{options[:with]} admin=#{resource.admin?}")
    AuditEventService.new(user, user, options)
      .for_authentication.security_event
  end

  def log_user_activity(user)
    login_counter.increment
    Users::ActivityService.new(user).execute
  end

  def load_recaptcha
    Gitlab::Recaptcha.load_configurations!
  end

  def unverified_anonymous_user?
    exceeded_failed_login_attempts? || exceeded_anonymous_sessions?
  end

  def exceeded_failed_login_attempts?
    session.fetch(:failed_login_attempts, 0) > MAX_FAILED_LOGIN_ATTEMPTS
  end

  def exceeded_anonymous_sessions?
    Gitlab::AnonymousSession.new(request.remote_ip).session_count >= MAX_FAILED_LOGIN_ATTEMPTS
  end

  def authentication_method
    if user_params[:otp_attempt]
      AuthenticationEvent::TWO_FACTOR
    elsif user_params[:device_response] && Feature.enabled?(:webauthn)
      AuthenticationEvent::TWO_FACTOR_WEBAUTHN
    elsif user_params[:device_response] && !Feature.enabled?(:webauthn)
      AuthenticationEvent::TWO_FACTOR_U2F
    else
      AuthenticationEvent::STANDARD
    end
  end

  def set_invite_params
    @invite_email = ActionController::Base.helpers.sanitize(params[:invite_email])
  end

  def check_forbidden_password_based_login
    if find_user&.password_based_login_forbidden?
      flash[:alert] = _('You are not allowed to log in using password')
      redirect_to new_user_session_path
    end
  end
end

SessionsController.prepend_mod_with('SessionsController')
