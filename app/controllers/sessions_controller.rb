class SessionsController < Devise::SessionsController
  include AuthenticatesWithTwoFactor
  include Recaptcha::ClientHelper

  skip_before_action :check_2fa_requirement, only: [:destroy]

  prepend_before_action :check_initial_setup, only: [:new]
  prepend_before_action :authenticate_with_two_factor,
    if: :two_factor_enabled?, only: [:create]
  prepend_before_action :store_redirect_path, only: [:new]
  before_action :gitlab_geo_login, only: [:new]
  before_action :auto_sign_in_with_provider, only: [:new]
  before_action :load_recaptcha

  def new
    if Gitlab.config.ldap.enabled
      @ldap_servers = Gitlab::LDAP::Config.servers
    else
      @ldap_servers = []
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
      authenticated_with = user_params[:otp_attempt] ? "two-factor" : "standard"
      log_audit_event(current_user, with: authenticated_with)
    end
  end

  private

  # Handle an "initial setup" state, where there's only one user, it's an admin,
  # and they require a password change.
  def check_initial_setup
    return unless User.count == 1

    user = User.admins.last

    return unless user && user.require_password?

    token = user.generate_reset_token
    user.save

    redirect_to edit_user_password_path(reset_password_token: token),
      notice: "Please create a password for your new account."
  end

  def user_params
    params.require(:user).permit(:login, :password, :remember_me, :otp_attempt)
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

  def authenticate_with_two_factor
    user = self.resource = find_user

    if user_params[:otp_attempt].present? && session[:otp_user_id]
      if valid_otp_attempt?(user)
        # Remove any lingering user data from login
        session.delete(:otp_user_id)

        sign_in(user) and return
      else
        flash.now[:alert] = 'Invalid two-factor code.'
        render :two_factor and return
      end
    else
      if user && user.valid_password?(user_params[:password])
        prompt_for_two_factor(user)
      end
    end
  end

  def gitlab_geo_login
    if !signed_in? && Gitlab::Geo.enabled? && Gitlab::Geo.secondary?
      oauth = Gitlab::Geo::OauthSession.new

      # share full url with primary node by shared session
      user_return_to = URI.join(root_url, session[:user_return_to].to_s).to_s
      oauth.return_to = @redirect_to || user_return_to

      redirect_to oauth_geo_auth_url(state: oauth.generate_oauth_state)
    end
  end

  def auto_sign_in_with_provider
    provider = Gitlab.config.omniauth.auto_sign_in_with_provider
    return unless provider.present?

    # Auto sign in with an Omniauth provider only if the standard "you need to sign-in" alert is
    # registered or no alert at all. In case of another alert (such as a blocked user), it is safer
    # to do nothing to prevent redirection loops with certain Omniauth providers.
    return unless flash[:alert].blank? || flash[:alert] == I18n.t('devise.failure.unauthenticated')

    # Prevent alert from popping up on the first page shown after authentication.
    flash[:alert] = nil

    redirect_to user_omniauth_authorize_path(provider.to_sym)
  end

  def valid_otp_attempt?(user)
    user.validate_and_consume_otp!(user_params[:otp_attempt]) ||
    user.invalidate_otp_backup_code!(user_params[:otp_attempt])
  end

  def log_audit_event(user, options = {})
    AuditEventService.new(user, user, options).
      for_authentication.security_event
  end

  def load_recaptcha
    Gitlab::Recaptcha.load_configurations!
  end
end
