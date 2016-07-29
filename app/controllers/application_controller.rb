require 'gon'
require 'fogbugz'

class ApplicationController < ActionController::Base
  include Gitlab::CurrentSettings
  include Gitlab::GonHelper
  include GitlabRoutingHelper
  include PageLayoutHelper
  include WorkhorseHelper

  before_action :authenticate_user_from_private_token!
  before_action :authenticate_user!
  before_action :validate_user_service_ticket!
  before_action :reject_blocked!
  before_action :check_password_expiration
  before_action :check_2fa_requirement
  before_action :ldap_security_check
  before_action :sentry_context
  before_action :default_headers
  before_action :add_gon_variables
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :require_email, unless: :devise_controller?

  protect_from_forgery with: :exception

  helper_method :abilities, :can?, :current_application_settings
  helper_method :import_sources_enabled?, :github_import_enabled?, :github_import_configured?, :gitlab_import_enabled?, :gitlab_import_configured?, :bitbucket_import_enabled?, :bitbucket_import_configured?, :gitorious_import_enabled?, :google_code_import_enabled?, :fogbugz_import_enabled?, :git_import_enabled?, :gitlab_project_import_enabled?

  rescue_from Encoding::CompatibilityError do |exception|
    log_exception(exception)
    render "errors/encoding", layout: "errors", status: 500
  end

  rescue_from ActiveRecord::RecordNotFound do |exception|
    log_exception(exception)
    render_404
  end

  rescue_from Gitlab::Access::AccessDeniedError do |exception|
    render_403
  end

  def redirect_back_or_default(default: root_path, options: {})
    redirect_to request.referer.present? ? :back : default, options
  end

  protected

  def sentry_context
    if Rails.env.production? && current_application_settings.sentry_enabled
      if current_user
        Raven.user_context(
          id: current_user.id,
          email: current_user.email,
          username: current_user.username,
        )
      end

      Raven.tags_context(program: sentry_program_context)
    end
  end

  def sentry_program_context
    if Sidekiq.server?
      'sidekiq'
    else
      'rails'
    end
  end

  # This filter handles both private tokens and personal access tokens
  def authenticate_user_from_private_token!
    token_string = params[:private_token].presence || request.headers['PRIVATE-TOKEN'].presence
    user = User.find_by_authentication_token(token_string) || User.find_by_personal_access_token(token_string)

    if user
      # Notice we are passing store false, so the user is not
      # actually stored in the session and a token is needed
      # for every request. If you want the token to work as a
      # sign in token, you can simply remove store: false.
      sign_in user, store: false
    end
  end

  def authenticate_user!(*args)
    if redirect_to_home_page_url?
      redirect_to current_application_settings.home_page_url and return
    end

    super(*args)
  end

  def log_exception(exception)
    application_trace = ActionDispatch::ExceptionWrapper.new(env, exception).application_trace
    application_trace.map!{ |t| "  #{t}\n" }
    logger.error "\n#{exception.class.name} (#{exception.message}):\n#{application_trace.join}"
  end

  def reject_blocked!
    if current_user && current_user.blocked?
      sign_out current_user
      flash[:alert] = "Your account is blocked. Retry when an admin has unblocked it."
      redirect_to new_user_session_path
    end
  end

  def after_sign_in_path_for(resource)
    if resource.is_a?(User) && resource.respond_to?(:blocked?) && resource.blocked?
      sign_out resource
      flash[:alert] = "Your account is blocked. Retry when an admin has unblocked it."
      new_user_session_path
    else
      stored_location_for(:redirect) || stored_location_for(resource) || root_path
    end
  end

  def after_sign_out_path_for(resource)
    if Gitlab::Geo.secondary?
      Gitlab::Geo.primary_node.oauth_logout_url(@geo_logout_state)
    else
      current_application_settings.after_sign_out_path.presence || new_user_session_path
    end
  end

  def abilities
    Ability.abilities
  end

  def can?(object, action, subject)
    abilities.allowed?(object, action, subject)
  end

  def access_denied!
    render "errors/access_denied", layout: "errors", status: 404
  end

  def git_not_found!
    render "errors/git_not_found.html", layout: "errors", status: 404
  end

  def render_403
    head :forbidden
  end

  def render_404
    render file: Rails.root.join("public", "404"), layout: false, status: "404"
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
    # Enabling HSTS for non-standard ports would send clients to the wrong port
    if Gitlab.config.gitlab.https and Gitlab.config.gitlab.port == 443
      headers['Strict-Transport-Security'] = 'max-age=31536000'
    end
  end

  def validate_user_service_ticket!
    return unless signed_in? && session[:service_tickets]

    valid = session[:service_tickets].all? do |provider, ticket|
      Gitlab::OAuth::Session.valid?(provider, ticket)
    end

    unless valid
      session[:service_tickets] = nil
      sign_out current_user
      redirect_to new_user_session_path
    end
  end

  def check_password_expiration
    if current_user && current_user.password_expires_at && current_user.password_expires_at < Time.now && !current_user.ldap_user?
      redirect_to new_profile_password_path and return
    end
  end

  def check_2fa_requirement
    if two_factor_authentication_required? && current_user && !current_user.two_factor_enabled? && !skip_two_factor?
      redirect_to profile_two_factor_auth_path
    end
  end

  def ldap_security_check
    if current_user && current_user.requires_ldap_check?
      return unless current_user.try_obtain_ldap_lease

      unless Gitlab::LDAP::Access.allowed?(current_user)
        sign_out current_user
        flash[:alert] = "Access denied for your LDAP account."
        redirect_to new_user_session_path
      end
    end
  end

  def event_filter
    filters = cookies['event_filter'].split(',') if cookies['event_filter'].present?
    @event_filter ||= EventFilter.new(filters)
  end

  def gitlab_ldap_access(&block)
    Gitlab::LDAP::Access.open { |access| block.call(access) }
  end

  # JSON for infinite scroll via Pager object
  def pager_json(partial, count)
    html = render_to_string(
      partial,
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
    if current_user && current_user.temp_oauth_email?
      redirect_to profile_path, notice: 'Please complete your profile with email address' and return
    end
  end

  def require_ldap_enabled
    unless Gitlab.config.ldap.enabled
      render_404 and return
    end
  end

  def set_filters_params
    set_default_sort

    params[:scope] = 'all' if params[:scope].blank?
    params[:state] = 'opened' if params[:state].blank?

    @sort = params[:sort]
    @filter_params = params.dup

    if @project
      @filter_params[:project_id] = @project.id
    elsif @group
      @filter_params[:group_id] = @group.id
    else
      # TODO: this filter ignore issues/mr created in public or
      # internal repos where you are not a member. Enable this filter
      # or improve current implementation to filter only issues you
      # created or assigned or mentioned
      # @filter_params[:authorized_only] = true
    end

    @filter_params
  end

  def get_issues_collection
    set_filters_params
    @issuable_finder = IssuesFinder.new(current_user, @filter_params)
    @issuable_finder.execute
  end

  def get_merge_requests_collection
    set_filters_params
    @issuable_finder = MergeRequestsFinder.new(current_user, @filter_params)
    @issuable_finder.execute
  end

  def import_sources_enabled?
    !current_application_settings.import_sources.empty?
  end

  def github_import_enabled?
    current_application_settings.import_sources.include?('github')
  end

  def github_import_configured?
    Gitlab::OAuth::Provider.enabled?(:github)
  end

  def gitlab_import_enabled?
    request.host != 'gitlab.com' && current_application_settings.import_sources.include?('gitlab')
  end

  def gitlab_import_configured?
    Gitlab::OAuth::Provider.enabled?(:gitlab)
  end

  def bitbucket_import_enabled?
    current_application_settings.import_sources.include?('bitbucket')
  end

  def bitbucket_import_configured?
    Gitlab::OAuth::Provider.enabled?(:bitbucket) && Gitlab::BitbucketImport.public_key.present?
  end

  def gitorious_import_enabled?
    current_application_settings.import_sources.include?('gitorious')
  end

  def google_code_import_enabled?
    current_application_settings.import_sources.include?('google_code')
  end

  def fogbugz_import_enabled?
    current_application_settings.import_sources.include?('fogbugz')
  end

  def git_import_enabled?
    current_application_settings.import_sources.include?('git')
  end

  def gitlab_project_import_enabled?
    current_application_settings.import_sources.include?('gitlab_project')
  end

  def two_factor_authentication_required?
    current_application_settings.require_two_factor_authentication
  end

  def two_factor_grace_period
    current_application_settings.two_factor_grace_period
  end

  def two_factor_grace_period_expired?
    date = current_user.otp_grace_period_started_at
    date && (date + two_factor_grace_period.hours) < Time.current
  end

  def skip_two_factor?
    session[:skip_tfa] && session[:skip_tfa] > Time.current
  end

  def redirect_to_home_page_url?
    # If user is not signed-in and tries to access root_path - redirect him to landing page
    # Don't redirect to the default URL to prevent endless redirections
    return false unless current_application_settings.home_page_url.present?

    home_page_url = current_application_settings.home_page_url.chomp('/')
    root_urls = [Gitlab.config.gitlab['url'].chomp('/'), root_url.chomp('/')]

    return false if root_urls.include?(home_page_url)

    current_user.nil? && root_path == request.path
  end

  # U2F (universal 2nd factor) devices need a unique identifier for the application
  # to perform authentication.
  # https://developers.yubico.com/U2F/App_ID.html
  def u2f_app_id
    request.base_url
  end

  private

  def set_default_sort
    key = if is_a_listing_page_for?('issues') || is_a_listing_page_for?('merge_requests')
            'issuable_sort'
          end

    cookies[key]  = params[:sort] if key && params[:sort].present?
    params[:sort] = cookies[key] if key
    params[:sort] ||= 'id_desc'
  end

  def is_a_listing_page_for?(page_type)
    controller_name, action_name = params.values_at(:controller, :action)

    (controller_name == "projects/#{page_type}" && action_name == 'index') ||
    (controller_name == 'groups' && action_name == page_type) ||
    (controller_name == 'dashboard' && action_name == page_type)
  end
end
