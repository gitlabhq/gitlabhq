require 'gon'
require 'fogbugz'

class ApplicationController < ActionController::Base
  include Gitlab::CurrentSettings
  include GitlabRoutingHelper
  include PageLayoutHelper

  PER_PAGE = 20

  before_action :authenticate_user_from_token!
  before_action :authenticate_user!
  before_action :reject_blocked!
  before_action :check_password_expiration
  before_action :ldap_security_check
  before_action :default_headers
  before_action :add_gon_variables
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :require_email, unless: :devise_controller?

  protect_from_forgery with: :exception

  helper_method :abilities, :can?, :current_application_settings
  helper_method :import_sources_enabled?, :github_import_enabled?, :github_import_configured?, :gitlab_import_enabled?, :gitlab_import_configured?, :bitbucket_import_enabled?, :bitbucket_import_configured?, :gitorious_import_enabled?, :google_code_import_enabled?, :fogbugz_import_enabled?, :git_import_enabled?

  rescue_from Encoding::CompatibilityError do |exception|
    log_exception(exception)
    render "errors/encoding", layout: "errors", status: 500
  end

  rescue_from ActiveRecord::RecordNotFound do |exception|
    log_exception(exception)
    render "errors/not_found", layout: "errors", status: 404
  end

  protected

  # From https://github.com/plataformatec/devise/wiki/How-To:-Simple-Token-Authentication-Example
  # https://gist.github.com/josevalim/fb706b1e933ef01e4fb6
  def authenticate_user_from_token!
    user_token = if params[:authenticity_token].presence
                   params[:authenticity_token].presence
                 elsif params[:private_token].presence
                   params[:private_token].presence
                 end
    user = user_token && User.find_by_authentication_token(user_token.to_s)

    if user
      # Notice we are passing store false, so the user is not
      # actually stored in the session and a token is needed
      # for every request. If you want the token to work as a
      # sign in token, you can simply remove store: false.
      sign_in user, store: false
    end
  end

  def authenticate_user!(*args)
    # If user is not signed-in and tries to access root_path - redirect him to landing page
    # Don't redirect to the default URL to prevent endless redirections
    if current_application_settings.home_page_url.present? &&
        current_application_settings.home_page_url.chomp('/') != Gitlab.config.gitlab['url'].chomp('/')
      if current_user.nil? && root_path == request.path
        redirect_to current_application_settings.home_page_url and return
      end
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
    current_application_settings.after_sign_out_path || new_user_session_path
  end

  def abilities
    Ability.abilities
  end

  def can?(object, action, subject)
    abilities.allowed?(object, action, subject)
  end

  def project
    unless @project
      namespace = params[:namespace_id]
      id = params[:project_id] || params[:id]

      # Redirect from
      #   localhost/group/project.git
      # to
      #   localhost/group/project
      #
      if id =~ /\.git\Z/
        redirect_to request.original_url.gsub(/\.git\Z/, '') and return
      end

      @project = Project.find_with_namespace("#{namespace}/#{id}")

      if @project and can?(current_user, :read_project, @project)
        @project
      elsif current_user.nil?
        @project = nil
        authenticate_user!
      else
        @project = nil
        render_404 and return
      end
    end
    @project
  end

  def repository
    @repository ||= project.repository
  end

  def authorize_project!(action)
    return access_denied! unless can?(current_user, action, project)
  end

  def access_denied!
    render "errors/access_denied", layout: "errors", status: 404
  end

  def not_found!
    render "errors/not_found", layout: "errors", status: 404
  end

  def git_not_found!
    render "errors/git_not_found", layout: "errors", status: 404
  end

  def method_missing(method_sym, *arguments, &block)
    if method_sym.to_s =~ /\Aauthorize_(.*)!\z/
      authorize_project!($1.to_sym)
    else
      super
    end
  end

  def render_403
    head :forbidden
  end

  def render_404
    render file: Rails.root.join("public", "404"), layout: false, status: "404"
  end

  def require_non_empty_project
    redirect_to @project if @project.empty_repo?
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

  def add_gon_variables
    gon.api_version            = API::API.version
    gon.default_avatar_url     = URI::join(Gitlab.config.gitlab.url, ActionController::Base.helpers.image_path('no_avatar.png')).to_s
    gon.default_issues_tracker = Project.new.default_issue_tracker.to_param
    gon.max_file_size          = current_application_settings.max_attachment_size
    gon.relative_url_root      = Gitlab.config.gitlab.relative_url_root
    gon.user_color_scheme      = Gitlab::ColorSchemes.for_user(current_user).css_class

    if current_user
      gon.current_user_id = current_user.id
      gon.api_token = current_user.private_token
    end
  end

  def check_password_expiration
    if current_user && current_user.password_expires_at && current_user.password_expires_at < Time.now  && !current_user.ldap_user?
      redirect_to new_profile_password_path and return
    end
  end

  def ldap_security_check
    if current_user && current_user.requires_ldap_check?
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

  def view_to_html_string(partial)
    render_to_string(
      partial,
      layout: false,
      formats: [:html]
    )
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.for(:sign_in) { |u| u.permit(:username, :email, :password, :login, :remember_me, :otp_attempt) }
  end

  def hexdigest(string)
    Digest::SHA1.hexdigest string
  end

  def require_email
    if current_user && current_user.temp_oauth_email?
      redirect_to profile_path, notice: 'Please complete your profile with email address' and return
    end
  end

  def set_filters_params
    params[:sort] ||= 'created_desc'
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
      #@filter_params[:authorized_only] = true
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
end
