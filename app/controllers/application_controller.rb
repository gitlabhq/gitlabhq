class ApplicationController < ActionController::Base
  before_filter :authenticate_user!
  before_filter :reject_blocked!
  before_filter :set_current_user_for_observers
  before_filter :add_abilities
  before_filter :dev_tools if Rails.env == 'development'
  before_filter :default_headers

  protect_from_forgery

  helper_method :abilities, :can?

  rescue_from Gitlab::Gitolite::AccessDenied do |exception|
    log_exception(exception)
    render "errors/gitolite", layout: "errors", status: 500
  end

  rescue_from Encoding::CompatibilityError do |exception|
    log_exception(exception)
    render "errors/encoding", layout: "errors", status: 500
  end

  rescue_from ActiveRecord::RecordNotFound do |exception|
    log_exception(exception)
    render "errors/not_found", layout: "errors", status: 404
  end

  protected

  def log_exception(exception)
    application_trace = ActionDispatch::ExceptionWrapper.new(env, exception).application_trace
    application_trace.map!{ |t| "  #{t}\n" }
    logger.error "\n#{exception.class.name} (#{exception.message}):\n#{application_trace.join}"
  end

  def reject_blocked!
    if current_user && current_user.blocked
      sign_out current_user
      flash[:alert] = "Your account is blocked. Retry when an admin unblock it."
      redirect_to new_user_session_path
    end
  end

  def after_sign_in_path_for resource
    if resource.is_a?(User) && resource.respond_to?(:blocked) && resource.blocked
      sign_out resource
      flash[:alert] = "Your account is blocked. Retry when an admin unblock it."
      new_user_session_path
    else
      super
    end
  end

  def set_current_user_for_observers
    MergeRequestObserver.current_user = current_user
    IssueObserver.current_user = current_user
  end

  def abilities
    @abilities ||= Six.new
  end

  def can?(object, action, subject)
    abilities.allowed?(object, action, subject)
  end

  def project
    id = params[:project_id] || params[:id]

    @project = Project.find_with_namespace(id)

    if @project and can?(current_user, :read_project, @project)
      @project
    else
      @project = nil
      render_404
    end
  end

  def repository
    @repository ||= project.repository
  rescue Grit::NoSuchPathError
    nil
  end

  def add_abilities
    abilities << Ability
  end

  def authorize_project!(action)
    return access_denied! unless can?(current_user, action, project)
  end

  def authorize_code_access!
    return access_denied! unless can?(current_user, :download_code, project)
  end

  def authorize_create_team!
    return access_denied! unless can?(current_user, :create_team, nil)
  end

  def authorize_manage_user_team!
    return access_denied! unless user_team.present? && can?(current_user, :manage_user_team, user_team)
  end

  def authorize_admin_user_team!
    return access_denied! unless user_team.present? && can?(current_user, :admin_user_team, user_team)
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
    if method_sym.to_s =~ /^authorize_(.*)!$/
      authorize_project!($1.to_sym)
    else
      super
    end
  end

  def render_404
    render file: Rails.root.join("public", "404"), layout: false, status: "404"
  end

  def render_403
    render file: Rails.root.join("public", "403"), layout: false, status: "403"
  end

  def require_non_empty_project
    redirect_to @project if @project.empty_repo?
  end

  def no_cache_headers
    response.headers["Cache-Control"] = "no-cache, no-store, max-age=0, must-revalidate"
    response.headers["Pragma"] = "no-cache"
    response.headers["Expires"] = "Fri, 01 Jan 1990 00:00:00 GMT"
  end

  def dev_tools
    Rack::MiniProfiler.authorize_request
  end

  def default_headers
    headers['X-Frame-Options'] = 'DENY'
    headers['X-XSS-Protection'] = '1; mode=block'
  end
end
