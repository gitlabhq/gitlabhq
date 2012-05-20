class ApplicationController < ActionController::Base
  before_filter :authenticate_user!
  before_filter :reject_blocked!
  before_filter :set_current_user_for_mailer
  protect_from_forgery
  helper_method :abilities, :can?

  rescue_from Gitlabhq::Gitolite::AccessDenied do |exception|
    render "errors/gitolite", :layout => "error"
  end

  rescue_from ActiveRecord::RecordNotFound do |exception|
    render "errors/not_found", :layout => "error", :status => 404
  end

  layout :layout_by_resource

  protected

  def reject_blocked!
    if current_user && current_user.blocked
      sign_out current_user 
      flash[:alert] = "Your account was blocked"
      redirect_to new_user_session_path
    end
  end

  def after_sign_in_path_for resource
    if resource.is_a?(User) && resource.respond_to?(:blocked) && resource.blocked
      sign_out resource
      flash[:alert] = "Your account was blocked"
      new_user_session_path
    else
      super
    end
  end

  def layout_by_resource
    if devise_controller?
      "devise"
    else
      "application"
    end
  end

  def set_current_user_for_mailer
    MailerObserver.current_user = current_user
  end

  def abilities
    @abilities ||= Six.new
  end

  def can?(object, action, subject)
    abilities.allowed?(object, action, subject)
  end

  def project
    @project ||= current_user.projects.find_by_code(params[:project_id])
    @project || render_404
  end

  def add_project_abilities
    abilities << Ability
  end

  def authenticate_admin!
    return render_404 unless current_user.is_admin?
  end

  def authorize_project!(action)
    return access_denied! unless can?(current_user, action, project)
  end

  def authorize_code_access!
    return access_denied! unless can?(current_user, :download_code, project)
  end

  def access_denied!
    render "errors/access_denied", :layout => "error", :status => 404
  end

  def not_found!
    render "errors/not_found", :layout => "error", :status => 404
  end

  def git_not_found!
    render "errors/git_not_found", :layout => "error", :status => 404
  end

  def method_missing(method_sym, *arguments, &block)
    if method_sym.to_s =~ /^authorize_(.*)!$/
      authorize_project!($1.to_sym)
    else
      super
    end
  end

  def load_refs
    if params[:ref].blank?
      @branch = params[:branch].blank? ? nil : params[:branch]
      @tag = params[:tag].blank? ? nil : params[:tag]
      @ref = @branch || @tag || @project.try(:default_branch) || Repository.default_ref
    else
      @ref = params[:ref]
    end
  end

  def render_404
    render :file => File.join(Rails.root, "public", "404"), :layout => false, :status => "404"
  end

  def require_non_empty_project
    redirect_to @project unless @project.repo_exists? && @project.has_commits?
  end

  def no_cache_headers
    response.headers["Cache-Control"] = "no-cache, no-store, max-age=0, must-revalidate"
    response.headers["Pragma"] = "no-cache"
    response.headers["Expires"] = "Fri, 01 Jan 1990 00:00:00 GMT"
  end

  def render_full_content
    @full_content = true
  end
end
