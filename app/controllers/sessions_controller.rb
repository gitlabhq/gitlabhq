class SessionsController < Devise::SessionsController
  include AuthenticatesWithTwoFactor
  include Devise::Controllers::Rememberable
  include Recaptcha::ClientHelper

  skip_before_action :check_two_factor_requirement, only: [:destroy]

  # Explicitly call protect from forgery before anything else. Otherwise the
  # CSFR-token might be cleared before authentication is done. This was the case
  # when LDAP was enabled and the `OmniauthCallbacksController` is loaded
  #
  # *Note:* `prepend: true` is the default for rails4, but this will be changed
  # to `prepend: false` in rails5.
  protect_from_forgery prepend: true, with: :exception

  prepend_before_action :check_initial_setup, only: [:new]
  prepend_before_action :authenticate_with_two_factor,
    if: :two_factor_enabled?, only: [:create]
  prepend_before_action :store_redirect_path, only: [:new]
  before_action :gitlab_geo_login, only: [:new]
  before_action :gitlab_geo_logout, only: [:destroy]
  before_action :auto_sign_in_with_provider, only: [:new]
  before_action :load_recaptcha

  def new
    set_minimum_password_length
    @ldap_servers =
      if Gitlab.config.ldap.enabled
        Gitlab::LDAP::Config.servers
      else
        []
      end

    super
  end

  def create
    super do |resource|
      # User has successfully signed in, so clear any unused reset token
      if resource.reset_password_token.present?
        resource.update_attributes(reset_password_token: nil,
                                   reset_password_sent_at: nil)
      end
      # hide the signed-in notification
      flash[:notice] = nil
      log_audit_event(current_user, with: authentication_method)
      log_user_activity(current_user)
    end
  end

  def destroy
    super
    # hide the signed_out notice
    flash[:notice] = nil
  end

  private

  def login_counter
    @login_counter ||= Gitlab::Metrics.counter(:user_session_logins_total, 'User sign in count')
  end

  # Handle an "initial setup" state, where there's only one user, it's an admin,
  # and they require a password change.
  def check_initial_setup
    return unless User.limit(2).count == 1 # Count as much 2 to know if we have exactly one

    user = User.admins.last

    return unless user && user.require_password_creation?

    Users::UpdateService.new(user).execute do |user|
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

  def store_redirect_path
    redirect_uri =
      if request.referer.present? && (params['redirect_to_referer'] == 'yes')
        URI(request.referer)
      else
        URI(request.url)
      end

    # Prevent a 'you are already signed in' message directly after signing:
    # we should never redirect to '/users/sign_in' after signing in successfully.
    if redirect_uri.path == new_user_session_path
      return true
    elsif redirect_uri.host == Gitlab.config.gitlab.host && redirect_uri.port == Gitlab.config.gitlab.port
      redirect_to = redirect_uri.to_s
    elsif Gitlab::Geo.geo_node?(host: redirect_uri.host, port: redirect_uri.port)
      redirect_to = redirect_uri.to_s
    end

    @redirect_to = redirect_to
    store_location_for(:redirect, redirect_to)
  end

  def two_factor_enabled?
    find_user.try(:two_factor_enabled?)
  end

  def gitlab_geo_login
    return unless Gitlab::Geo.secondary?
    return if signed_in?

    oauth = Gitlab::Geo::OauthSession.new

    # share full url with primary node by oauth state
    user_return_to = URI.join(root_url, session[:user_return_to].to_s).to_s
    oauth.return_to = @redirect_to || user_return_to

    redirect_to oauth_geo_auth_url(state: oauth.generate_oauth_state)
  end

  def gitlab_geo_logout
    return unless Gitlab::Geo.secondary?

    oauth = Gitlab::Geo::OauthSession.new(access_token: session[:access_token])
    @geo_logout_state = oauth.generate_logout_state
  end

  def auto_sign_in_with_provider
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

  def log_audit_event(user, options = {})
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
