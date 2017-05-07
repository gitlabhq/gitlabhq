class Projects::ApplicationController < ApplicationController
  include RoutableActions

  skip_before_action :authenticate_user!
  before_action :redirect_git_extension
  before_action :project
  before_action :repository
  layout 'project'

  helper_method :repository, :can_collaborate_with_project?

  private

  def redirect_git_extension
    # Redirect from
    #   localhost/group/project.git
    # to
    #   localhost/group/project
    #
    redirect_to url_for(params.merge(format: nil)) if params[:format] == 'git'
  end

  def project
    return @project if @project

    path = File.join(params[:namespace_id], params[:project_id] || params[:id])
    auth_proc = ->(project) { !project.pending_delete? }

    @project = find_routable!(Project, path, extra_authorization_proc: auth_proc)
  end

  def repository
    @repository ||= project.repository
  end

  def can_collaborate_with_project?(project = nil)
    project ||= @project

    can?(current_user, :push_code, project) ||
      (current_user && current_user.already_forked?(project))
  end

  def authorize_action!(action)
    unless can?(current_user, action, project)
      return access_denied!
    end
  end

  def method_missing(method_sym, *arguments, &block)
    if method_sym.to_s =~ /\Aauthorize_(.*)!\z/
      authorize_action!($1.to_sym)
    else
      super
    end
  end

  def require_non_empty_project
    # Be sure to return status code 303 to avoid a double DELETE:
    # http://api.rubyonrails.org/classes/ActionController/Redirecting.html
    redirect_to namespace_project_path(@project.namespace, @project), status: 303 if @project.empty_repo?
  end

  def require_branch_head
    unless @repository.branch_exists?(@ref)
      redirect_to(
        namespace_project_tree_path(@project.namespace, @project, @ref),
        notice: "This action is not allowed unless you are on a branch"
      )
    end
  end

  def apply_diff_view_cookie!
    cookies.permanent[:diff_view] = params.delete(:view) if params[:view].present?
  end

  def builds_enabled
    return render_404 unless @project.feature_available?(:builds, current_user)
  end

  def require_pages_enabled!
    not_found unless Gitlab.config.pages.enabled
  end
end
