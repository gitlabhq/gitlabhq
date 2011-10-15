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

  def load_refs
    @branch = unless params[:branch].blank?
                params[:branch]
              else
                nil
              end

    @tag = unless params[:tag].blank?
             params[:tag]
           else 
             nil
           end

    @ref = @branch || @tag || "master"
  end

  def render_404
    render :file => File.join(Rails.root, "public", "404"), :layout => false, :status => "404"
  end

  def require_non_empty_project
    redirect_to @project unless @project.repo_exists?
  end
end
