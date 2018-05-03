require 'gon'
require 'fogbugz'

class ApplicationController < ActionController::Base
  include Gitlab::GonHelper
  include GitlabRoutingHelper
  include PageLayoutHelper
  include SafeParamsHelper
  include SentryHelper
  include WorkhorseHelper
  include EnforcesTwoFactorAuthentication
  include WithPerformanceBar

  before_action :authenticate_sessionless_user!
  before_action :authenticate_user!
  before_action :validate_user_service_ticket!
  before_action :check_password_expiration
  before_action :ldap_security_check
  before_action :sentry_context
  before_action :default_headers
  before_action :add_gon_variables, unless: -> { request.path.start_with?('/-/peek') }
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :require_email, unless: :devise_controller?

  around_action :set_locale

  after_action :set_page_title_header, if: -> { request.format == :json }

  protect_from_forgery with: :exception

  helper_method :can?
  helper_method :import_sources_enabled?, :github_import_enabled?, :gitea_import_enabled?, :github_import_configured?, :gitlab_import_enabled?, :gitlab_import_configured?, :bitbucket_import_enabled?, :bitbucket_import_configured?, :google_code_import_enabled?, :fogbugz_import_enabled?, :git_import_enabled?, :gitlab_project_import_enabled?

  rescue_from Encoding::CompatibilityError do |exception|
    log_exception(exception)
    render "errors/encoding", layout: "errors", status: 500
  end

  rescue_from ActiveRecord::RecordNotFound do |exception|
    log_exception(exception)
    render_404
  end

  rescue_from(ActionController::UnknownFormat) do
    render_404
  end

  rescue_from Gitlab::Access::AccessDeniedError do |exception|
    render_403
  end

  rescue_from Gitlab::Auth::TooManyIps do |e|
    head :forbidden, retry_after: Gitlab::Auth::UniqueIpsLimiter.config.unique_ips_limit_time_window
  end

  rescue_from Gitlab::Git::Storage::Inaccessible, GRPC::Unavailable, Gitlab::Git::CommandError do |exception|
    Raven.capture_exception(exception) if sentry_enabled?
    log_exception(exception)

    headers['Retry-After'] = exception.retry_after if exception.respond_to?(:retry_after)

    render_503
  end

  def redirect_back_or_default(default: root_path, options: {})
    redirect_to request.referer.present? ? :back : default, options
  end

  def not_found
    render_404
  end

  def route_not_found
    if current_user
      not_found
    else
      authenticate_user!
    end
  end

  protected

  def append_info_to_payload(payload)
    super
    payload[:remote_ip] = request.remote_ip

    logged_user = auth_user

    if logged_user.present?
      payload[:user_id] = logged_user.try(:id)
      payload[:username] = logged_user.try(:username)
    end
  end

  # Controllers such as GitHttpController may use alternative methods
  # (e.g. tokens) to authenticate the user, whereas Devise sets current_user
  def auth_user
    return current_user if current_user.present?

    return try(:authenticated_user)
  end

  # This filter handles personal access tokens, and atom requests with rss tokens
  def authenticate_sessionless_user!
    user = Gitlab::Auth::RequestAuthenticator.new(request).find_sessionless_user

    sessionless_sign_in(user) if user
  end

  def log_exception(exception)
    Raven.capture_exception(exception) if sentry_enabled?

    backtrace_cleaner = Gitlab.rails5? ? env["action_dispatch.backtrace_cleaner"] : env
    application_trace = ActionDispatch::ExceptionWrapper.new(backtrace_cleaner, exception).application_trace
    application_trace.map! { |t| "  #{t}\n" }
    logger.error "\n#{exception.class.name} (#{exception.message}):\n#{application_trace.join}"
  end

  def after_sign_in_path_for(resource)
    stored_location_for(:redirect) || stored_location_for(resource) || root_path
  end

  def after_sign_out_path_for(resource)
    Gitlab::CurrentSettings.after_sign_out_path.presence || new_user_session_path
  end

  def can?(object, action, subject = :global)
    Ability.allowed?(object, action, subject)
  end

  def access_denied!(message = nil)
    respond_to do |format|
      format.any { head :not_found }
      format.html do
        render "errors/access_denied",
               layout: "errors",
               status: 404,
               locals: { message: message }
      end
    end
  end

  def git_not_found!
    render "errors/git_not_found.html", layout: "errors", status: 404
  end

  def render_403
    head :forbidden
  end

  def render_404
    respond_to do |format|
      format.html do
        render file: Rails.root.join("public", "404"), layout: false, status: "404"
      end
      # Prevent the Rails CSRF protector from thinking a missing .js file is a JavaScript file
      format.js { render json: '', status: :not_found, content_type: 'application/json' }
      format.any { head :not_found }
    end
  end

  def respond_422
    head :unprocessable_entity
  end

  def render_503
    respond_to do |format|
      format.html do
        render(
          file: Rails.root.join("public", "503"),
          layout: false,
          status: :service_unavailable
        )
      end
      format.any { head :service_unavailable }
    end
  end

  def no_cache_headers
    response.headers["Cache-Control"] = "no-cache, no-store, max-age=0, must-revalidate"
    response.headers["Pragma"] = "no-cache"
    response.headers["Expires"] = "Fri, 01 Jan 1990 00:00:00 GMT"
  end

  def default_headers
    headers['X-Frame-Options'] = 'DENY'
    headers['X-XSS-Protection'] = '1; mode=block'
    headers['X-UA-Compatible'] = 'IE=edge'
    headers['X-Content-Type-Options'] = 'nosniff'
  end

  def validate_user_service_ticket!
    return unless signed_in? && session[:service_tickets]

    valid = session[:service_tickets].all? do |provider, ticket|
      Gitlab::Auth::OAuth::Session.valid?(provider, ticket)
    end

    unless valid
      session[:service_tickets] = nil
      sign_out current_user
      redirect_to new_user_session_path
    end
  end

  def check_password_expiration
    return if session[:impersonator_id] || !current_user&.allow_password_authentication?

    password_expires_at = current_user&.password_expires_at

    if password_expires_at && password_expires_at < Time.now
      return redirect_to new_profile_password_path
    end
  end

  def ldap_security_check
    if current_user && current_user.requires_ldap_check?
      return unless current_user.try_obtain_ldap_lease

      unless Gitlab::Auth::LDAP::Access.allowed?(current_user)
        sign_out current_user
        flash[:alert] = "Access denied for your LDAP account."
        redirect_to new_user_session_path
      end
    end
  end

  def event_filter
    # Split using comma to maintain backward compatibility Ex/ "filter1,filter2"
    filters = cookies['event_filter'].split(',')[0] if cookies['event_filter'].present?
    @event_filter ||= EventFilter.new(filters)
  end

  # JSON for infinite scroll via Pager object
  def pager_json(partial, count, locals = {})
    html = render_to_string(
      partial,
      locals: locals,
      layout: false,
      formats: [:html]
    )

    render json: {
      html: html,
      count: count
    }
  end

  def view_to_html_string(partial, locals = {})
    render_to_string(
      partial,
      locals: locals,
      layout: false,
      formats: [:html]
    )
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_in, keys: [:username, :email, :password, :login, :remember_me, :otp_attempt])
  end

  def hexdigest(string)
    Digest::SHA1.hexdigest string
  end

  def require_email
    if current_user && current_user.temp_oauth_email? && session[:impersonator_id].nil?
      return redirect_to profile_path, notice: 'Please complete your profile with email address'
    end
  end

  def import_sources_enabled?
    !Gitlab::CurrentSettings.import_sources.empty?
  end

  def github_import_enabled?
    Gitlab::CurrentSettings.import_sources.include?('github')
  end

  def gitea_import_enabled?
    Gitlab::CurrentSettings.import_sources.include?('gitea')
  end

  def github_import_configured?
    Gitlab::Auth::OAuth::Provider.enabled?(:github)
  end

  def gitlab_import_enabled?
    request.host != 'gitlab.com' && Gitlab::CurrentSettings.import_sources.include?('gitlab')
  end

  def gitlab_import_configured?
    Gitlab::Auth::OAuth::Provider.enabled?(:gitlab)
  end

  def bitbucket_import_enabled?
    Gitlab::CurrentSettings.import_sources.include?('bitbucket')
  end

  def bitbucket_import_configured?
    Gitlab::Auth::OAuth::Provider.enabled?(:bitbucket)
  end

  def google_code_import_enabled?
    Gitlab::CurrentSettings.import_sources.include?('google_code')
  end

  def fogbugz_import_enabled?
    Gitlab::CurrentSettings.import_sources.include?('fogbugz')
  end

  def git_import_enabled?
    Gitlab::CurrentSettings.import_sources.include?('git')
  end

  def gitlab_project_import_enabled?
    Gitlab::CurrentSettings.import_sources.include?('gitlab_project')
  end

  # U2F (universal 2nd factor) devices need a unique identifier for the application
  # to perform authentication.
  # https://developers.yubico.com/U2F/App_ID.html
  def u2f_app_id
    request.base_url
  end

  def set_locale(&block)
    Gitlab::I18n.with_user_locale(current_user, &block)
  end

  def sessionless_sign_in(user)
    if user && can?(user, :log_in)
      # Notice we are passing store false, so the user is not
      # actually stored in the session and a token is needed
      # for every request. If you want the token to work as a
      # sign in token, you can simply remove store: false.
      sign_in user, store: false
    end
  end

  def set_page_title_header
    # Per https://tools.ietf.org/html/rfc5987, headers need to be ISO-8859-1, not UTF-8
    response.headers['Page-Title'] = URI.escape(page_title('GitLab'))
  end
end
