# frozen_string_literal: true

require 'gon'
require 'fogbugz'

class ApplicationController < ActionController::Base
  include Gitlab::GonHelper
  include GitlabRoutingHelper
  include PageLayoutHelper
  include SafeParamsHelper
  include WorkhorseHelper
  include EnforcesTwoFactorAuthentication
  include WithPerformanceBar
  include SessionlessAuthentication
  include ConfirmEmailWarning

  before_action :authenticate_user!
  before_action :enforce_terms!, if: :should_enforce_terms?
  before_action :validate_user_service_ticket!
  before_action :check_password_expiration
  before_action :ldap_security_check
  before_action :sentry_context
  before_action :default_headers
  before_action :add_gon_variables, unless: [:peek_request?, :json_request?]
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :require_email, unless: :devise_controller?
  before_action :set_usage_stats_consent_flag
  before_action :check_impersonation_availability

  around_action :set_locale
  around_action :set_session_storage

  after_action :set_page_title_header, if: :json_request?
  after_action :limit_unauthenticated_session_times

  protect_from_forgery with: :exception, prepend: true

  helper_method :can?
  helper_method :import_sources_enabled?, :github_import_enabled?,
    :gitea_import_enabled?, :github_import_configured?,
    :gitlab_import_enabled?, :gitlab_import_configured?,
    :bitbucket_import_enabled?, :bitbucket_import_configured?,
    :bitbucket_server_import_enabled?,
    :google_code_import_enabled?, :fogbugz_import_enabled?,
    :git_import_enabled?, :gitlab_project_import_enabled?,
    :manifest_import_enabled?, :phabricator_import_enabled?

  # Adds `no-store` to the DEFAULT_CACHE_CONTROL, to prevent security
  # concerns due to caching private data.
  DEFAULT_GITLAB_CACHE_CONTROL = "#{ActionDispatch::Http::Cache::Response::DEFAULT_CACHE_CONTROL}, no-store".freeze
  DEFAULT_GITLAB_CONTROL_NO_CACHE = "#{DEFAULT_GITLAB_CACHE_CONTROL}, no-cache".freeze

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

  rescue_from GRPC::Unavailable, Gitlab::Git::CommandError do |exception|
    log_exception(exception)

    headers['Retry-After'] = exception.retry_after if exception.respond_to?(:retry_after)

    render_503
  end

  def redirect_back_or_default(default: root_path, options: {})
    redirect_back(fallback_location: default, **options)
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

  # By default, all sessions are given the same expiration time configured in
  # the session store (e.g. 1 week). However, unauthenticated users can
  # generate a lot of sessions, primarily for CSRF verification. It makes
  # sense to reduce the TTL for unauthenticated to something much lower than
  # the default (e.g. 1 hour) to limit Redis memory. In addition, Rails
  # creates a new session after login, so the short TTL doesn't even need to
  # be extended.
  def limit_unauthenticated_session_times
    return if current_user

    # Rack sets this header, but not all tests may have it: https://github.com/rack/rack/blob/fdcd03a3c5a1c51d1f96fc97f9dfa1a9deac0c77/lib/rack/session/abstract/id.rb#L251-L259
    return unless request.env['rack.session.options']

    # This works because Rack uses these options every time a request is handled:
    # https://github.com/rack/rack/blob/fdcd03a3c5a1c51d1f96fc97f9dfa1a9deac0c77/lib/rack/session/abstract/id.rb#L342
    request.env['rack.session.options'][:expire_after] = Settings.gitlab['unauthenticated_session_expire_delay']
  end

  def render(*args)
    super.tap do
      # Set a header for custom error pages to prevent them from being intercepted by gitlab-workhorse
      if (400..599).cover?(response.status) && workhorse_excluded_content_types.include?(response.content_type)
        response.headers['X-GitLab-Custom-Error'] = '1'
      end
    end
  end

  protected

  def workhorse_excluded_content_types
    @workhorse_excluded_content_types ||= %w(text/html application/json)
  end

  def append_info_to_payload(payload)
    super

    payload[:ua] = request.env["HTTP_USER_AGENT"]
    payload[:remote_ip] = request.remote_ip
    payload[Labkit::Correlation::CorrelationId::LOG_KEY] = Labkit::Correlation::CorrelationId.current_id

    logged_user = auth_user

    if logged_user.present?
      payload[:user_id] = logged_user.try(:id)
      payload[:username] = logged_user.try(:username)
    end

    if response.status == 422 && response.body.present? && response.content_type == 'application/json'.freeze
      payload[:response] = response.body
    end

    payload[:queue_duration] = request.env[::Gitlab::Middleware::RailsQueueDuration::GITLAB_RAILS_QUEUE_DURATION_KEY]
  end

  ##
  # Controllers such as GitHttpController may use alternative methods
  # (e.g. tokens) to authenticate the user, whereas Devise sets current_user.
  #
  def auth_user
    if user_signed_in?
      current_user
    else
      try(:authenticated_user)
    end
  end

  def log_exception(exception)
    Gitlab::Sentry.track_acceptable_exception(exception)

    backtrace_cleaner = request.env["action_dispatch.backtrace_cleaner"]
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

  def access_denied!(message = nil, status = nil)
    # If we display a custom access denied message to the user, we don't want to
    # hide existence of the resource, rather tell them they cannot access it using
    # the provided message
    status ||= message.present? ? :forbidden : :not_found
    template =
      if status == :not_found
        "errors/not_found"
      else
        "errors/access_denied"
      end

    respond_to do |format|
      format.any { head status }
      format.html do
        render template,
               layout: "errors",
               status: status,
               locals: { message: message }
      end
    end
  end

  def git_not_found!
    render "errors/git_not_found.html", layout: "errors", status: 404
  end

  def render_403
    respond_to do |format|
      format.any { head :forbidden }
      format.html { render "errors/access_denied", layout: "errors", status: 403 }
    end
  end

  def render_404
    respond_to do |format|
      format.html { render "errors/not_found", layout: "errors", status: 404 }
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
    headers['Cache-Control'] = DEFAULT_GITLAB_CONTROL_NO_CACHE
    headers['Pragma'] = 'no-cache' # HTTP 1.0 compatibility
    headers['Expires'] = 'Fri, 01 Jan 1990 00:00:00 GMT'
  end

  def default_headers
    headers['X-Frame-Options'] = 'DENY'
    headers['X-XSS-Protection'] = '1; mode=block'
    headers['X-UA-Compatible'] = 'IE=edge'
    headers['X-Content-Type-Options'] = 'nosniff'

    if current_user
      headers['Cache-Control'] = default_cache_control
      headers['Pragma'] = 'no-cache' # HTTP 1.0 compatibility
    end
  end

  def default_cache_control
    if request.xhr?
      ActionDispatch::Http::Cache::Response::DEFAULT_CACHE_CONTROL
    else
      DEFAULT_GITLAB_CACHE_CONTROL
    end
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
        flash[:alert] = _("Access denied for your LDAP account.")
        redirect_to new_user_session_path
      end
    end
  end

  def event_filter
    @event_filter ||=
      EventFilter.new(params[:event_filter].presence || cookies[:event_filter]).tap do |new_event_filter|
        cookies[:event_filter] = new_event_filter.filter
      end
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
      return redirect_to profile_path, notice: _('Please complete your profile with email address')
    end
  end

  def enforce_terms!
    return unless current_user
    return if current_user.terms_accepted?

    message = _("Please accept the Terms of Service before continuing.")

    if sessionless_user?
      access_denied!(message)
    else
      # Redirect to the destination if the request is a get.
      # Redirect to the source if it was a post, so the user can re-submit after
      # accepting the terms.
      redirect_path = if request.get?
                        request.fullpath
                      else
                        URI(request.referer).path if request.referer
                      end

      flash[:notice] = message
      redirect_to terms_path(redirect: redirect_path), status: :found
    end
  end

  def import_sources_enabled?
    !Gitlab::CurrentSettings.import_sources.empty?
  end

  def bitbucket_server_import_enabled?
    Gitlab::CurrentSettings.import_sources.include?('bitbucket_server')
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

  def manifest_import_enabled?
    Gitlab::CurrentSettings.import_sources.include?('manifest')
  end

  def phabricator_import_enabled?
    Gitlab::PhabricatorImport.available?
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

  def set_session_storage(&block)
    return yield if sessionless_user?

    Gitlab::Session.with_session(session, &block)
  end

  def set_page_title_header
    # Per https://tools.ietf.org/html/rfc5987, headers need to be ISO-8859-1, not UTF-8
    response.headers['Page-Title'] = URI.escape(page_title('GitLab'))
  end

  def peek_request?
    request.path.start_with?('/-/peek')
  end

  def json_request?
    request.format.json?
  end

  def should_enforce_terms?
    return false unless Gitlab::CurrentSettings.current_application_settings.enforce_terms

    !(peek_request? || devise_controller?)
  end

  def set_usage_stats_consent_flag
    return unless current_user
    return if sessionless_user?
    return if session.has_key?(:ask_for_usage_stats_consent)

    session[:ask_for_usage_stats_consent] = current_user.requires_usage_stats_consent?

    if session[:ask_for_usage_stats_consent]
      disable_usage_stats
    end
  end

  def disable_usage_stats
    application_setting_params = {
      usage_ping_enabled: false,
      version_check_enabled: false,
      skip_usage_stats_user: true
    }
    settings = Gitlab::CurrentSettings.current_application_settings

    ApplicationSettings::UpdateService
      .new(settings, current_user, application_setting_params)
      .execute
  end

  def check_impersonation_availability
    return unless session[:impersonator_id]

    unless Gitlab.config.gitlab.impersonation_enabled
      stop_impersonation
      access_denied! _('Impersonation has been disabled')
    end
  end

  def stop_impersonation
    log_impersonation_event

    warden.set_user(impersonator, scope: :user)
    session[:impersonator_id] = nil

    impersonated_user
  end

  def impersonated_user
    current_user
  end

  def log_impersonation_event
    Gitlab::AppLogger.info("User #{impersonator.username} has stopped impersonating #{impersonated_user.username}")
  end

  def impersonator
    @impersonator ||= User.find(session[:impersonator_id]) if session[:impersonator_id]
  end

  def sentry_context
    Gitlab::Sentry.context(current_user)
  end

  def allow_gitaly_ref_name_caching
    ::Gitlab::GitalyClient.allow_ref_name_caching do
      yield
    end
  end
end
