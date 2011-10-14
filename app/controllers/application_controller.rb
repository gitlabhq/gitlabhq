class ApplicationController < ActionController::Base
  before_filter :authenticate_user!
  protect_from_forgery

  helper_method :abilities, :can?

  rescue_from Gitosis::AccessDenied do |exception|
    render :file => File.join(Rails.root, "public", "gitosis_error"), :layout => false
  end

  protected 

  def abilities
    @abilities ||= Six.new
  end

  def can?(object, action, subject)
    abilities.allowed?(object, action, subject)
  end

  def project 
    @project ||= Project.find_by_code(params[:project_id])
  end

  def add_project_abilities
    abilities << Ability
  end

  def authenticate_admin!
    return redirect_to(new_user_session_path) unless current_user.is_admin?
  end

  def authorize_project!(action)
    return redirect_to(new_user_session_path) unless can?(current_user, action, project)
  end

  def method_missing(method_sym, *arguments, &block)
    if method_sym.to_s =~ /^authorize_(.*)!$/
      authorize_project!($1.to_sym)
    else
      super
    end
  end

  def refs_from_cookie
    # branch is high priority so we should reset
    # it if tag selected
    cookies[:branch] = nil if params[:tag]

    params[:branch] ||= cookies[:branch]
    params[:tag] ||= cookies[:tag]
  end
end
