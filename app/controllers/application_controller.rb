class ApplicationController < ActionController::Base
  before_filter :authenticate_user!
  before_filter :view_style

  protect_from_forgery

  helper_method :abilities, :can?

  rescue_from Gitosis::AccessDenied do |exception|
    render :file => File.join(Rails.root, "public", "gitosis_error"), :layout => false
  end

  layout :layout_by_resource

  protected

  def layout_by_resource
    if devise_controller?
      "devise"
    else
      "application"
    end
  end

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
    return render_404 unless current_user.is_admin?
  end

  def authorize_project!(action)
    return render_404 unless can?(current_user, action, project)
  end

  def access_denied!
    render_404
  end

  def method_missing(method_sym, *arguments, &block)
    if method_sym.to_s =~ /^authorize_(.*)!$/
      authorize_project!($1.to_sym)
    else
      super
    end
  end

  def load_refs
    unless params[:ref].blank?
      @ref = params[:ref]
    else
      @branch = params[:branch].blank? ? nil : params[:branch]
      @tag = params[:tag].blank? ? nil : params[:tag]
      @ref = @branch || @tag || Repository.default_ref
    end
  end

  def render_404
    render :file => File.join(Rails.root, "public", "404"), :layout => false, :status => "404"
  end

  def require_non_empty_project
    redirect_to @project unless @project.repo_exists?
  end

  def view_style
    if params[:view_style] == "collapsed"
      cookies[:view_style] = "collapsed" 
    elsif params[:view_style] == "fluid"
      cookies[:view_style] = "fluid" 
    end

    @view_mode = if cookies[:view_style] == "fluid"
                   :fluid
                 else
                   :collapsed
                 end
  end

  def respond_with_notes
    if params[:last_id] && params[:first_id]
      @notes = @notes.where("id >= ?", params[:first_id])
    elsif params[:last_id]
      @notes = @notes.where("id > ?", params[:last_id])
    elsif params[:first_id]
      @notes = @notes.where("id < ?", params[:first_id]) 
    else 
      nil
    end
  end
end
