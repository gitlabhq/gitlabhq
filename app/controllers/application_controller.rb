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
    if @project && session[:ui] && 
      session[:ui][@project.id]
      project_session = session[:ui][@project.id]
      project_session[:branch] = nil if params[:tag]
      params[:branch] ||= project_session[:branch]
      params[:tag] ||= project_session[:tag]
    end
  rescue 
    session[:ui] = nil
  end
end
