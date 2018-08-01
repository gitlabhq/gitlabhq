class SessionsController < Devise::SessionsController
  include InternalRedirect
  include AuthenticatesWithTwoFactor
  include Devise::Controllers::Rememberable
  include Recaptcha::ClientHelper
  include Recaptcha::Verify
  prepend EE::SessionsController

  skip_before_action :check_two_factor_requirement, only: [:destroy]

  prepend_before_action :check_initial_setup, only: [:new]
  prepend_before_action :authenticate_with_two_factor,
    if: :two_factor_enabled?, only: [:create]
  prepend_before_action :check_captcha, only: [:create]
  prepend_before_action :store_redirect_uri, only: [:new]
  prepend_before_action :ldap_servers, only: [:new, :create]
  before_action :auto_sign_in_with_provider, only: [:new]
  before_action :load_recaptcha

  after_action :log_failed_login, only: [:new], if: :failed_login?

  helper_method :captcha_enabled?

  CAPTCHA_HEADER = 'X-GitLab-Show-Login-Captcha'.freeze

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

      # hide the signed-in notification
      flash[:notice] = nil
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

  def captcha_enabled?
    request.headers[CAPTCHA_HEADER] && Gitlab::Recaptcha.enabled?
  end

  # From https://github.com/plataformatec/devise/wiki/How-To:-Use-Recaptcha-with-Devise#devisepasswordscontroller
  def check_captcha
    return unless user_params[:password].present?
    return unless captcha_enabled?
    return unless Gitlab::Recaptcha.load_configurations!

    if verify_recaptcha
      increment_successful_login_captcha_counter
    else
      increment_failed_login_captcha_counter

      self.resource = resource_class.new
      flash[:alert] = 'There was an error with the reCAPTCHA. Please solve the reCAPTCHA again.'
      flash.delete :recaptcha_error

      respond_with_navigational(resource) { render :new }
    end
  end

  def increment_failed_login_captcha_counter
    Gitlab::Metrics.counter(
      :failed_login_captcha_total,
      'Number of failed CAPTCHA attempts for logins'.freeze
    ).increment
  end

  def increment_successful_login_captcha_counter
    Gitlab::Metrics.counter(
      :successful_login_captcha_total,
      'Number of successful CAPTCHA attempts for logins'.freeze
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

  def failed_login?
    (options = env["warden.options"]) && options[:action] == "unauthenticated"
  end

  # Handle an "initial setup" state, where there's only one user, it's an admin,
  # and they require a password change.
  def check_initial_setup
    return unless User.limit(2).count == 1 # Count as much 2 to know if we have exactly one

    user = User.admins.last

    return unless user && user.require_password_creation_for_web?

    Users::UpdateService.new(current_user, user: user).execute do |user|
      @token = user.generate_reset_token
    end

    redirect_to edit_user_password_path(reset_password_token: @token),
      notice: "Please create a password for your new account."
  end

  def user_params
    params.require(:user).permit(:login, :password, :remember_me, :otp_attempt, :device_response)
  end

  def find_user
    if session[:otp_user_id]
      User.find(session[:otp_user_id])
    elsif user_params[:login]
      User.by_login(user_params[:login])
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
    user.validate_and_consume_otp!(user_params[:otp_attempt]) ||
      user.invalidate_otp_backup_code!(user_params[:otp_attempt])
  end

  def log_audit_event(user, resource, options = {})
    Gitlab::AppLogger.info("Successful Login: username=#{resource.username} ip=#{request.remote_ip} method=#{options[:with]} admin=#{resource.admin?}")
    AuditEventService.new(user, user, options)
      .for_authentication.security_event
  end

  def log_user_activity(user)
    login_counter.increment
    Users::ActivityService.new(user, 'login').execute
  end

  def load_recaptcha
    Gitlab::Recaptcha.load_configurations!
  end

  def ldap_servers
    @ldap_servers ||= Gitlab::Auth::LDAP::Config.available_servers
  end

  def authentication_method
    if user_params[:otp_attempt]
      "two-factor"
    elsif user_params[:device_response]
      "two-factor-via-u2f-device"
    else
      "standard"
    end
  end
end
