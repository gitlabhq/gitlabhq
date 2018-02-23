class Projects::ApplicationController < ApplicationController
  prepend EE::Projects::ApplicationController
  include RoutableActions

  skip_before_action :authenticate_user!
  before_action :project
  before_action :repository
  layout 'project'

  helper_method :repository, :can_collaborate_with_project?, :user_access

  private

  def project
    return @project if @project
    return nil unless params[:project_id] || params[:id]

    path = File.join(params[:namespace_id], params[:project_id] || params[:id])
    auth_proc = ->(project) { !project.pending_delete? }

    @project = find_routable!(Project, path, extra_authorization_proc: auth_proc)
  end

  def build_canonical_path(project)
    params[:namespace_id] = project.namespace.to_param
    params[:project_id] = project.to_param

    url_for(params)
  end

  def repository
    @repository ||= project.repository
  end

  def can_collaborate_with_project?(project = nil, ref: nil)
    project ||= @project

    can?(current_user, :push_code, project) ||
      (current_user && current_user.already_forked?(project)) ||
      user_access(project).can_push_to_branch?(ref)
  end

  def authorize_action!(action)
    unless can?(current_user, action, project)
      return access_denied!
    end
  end

  def check_project_feature_available!(feature)
    render_404 unless project.feature_available?(feature, current_user)
  end

  def check_issuables_available!
    render_404 unless project.feature_available?(:issues, current_user) ||
        project.feature_available?(:merge_requests, current_user)
  end

  def method_missing(method_sym, *arguments, &block)
    case method_sym.to_s
    when /\Aauthorize_(.*)!\z/
      authorize_action!($1.to_sym)
    when /\Acheck_(.*)_available!\z/
      check_project_feature_available!($1.to_sym)
    else
      super
    end
  end

  def require_non_empty_project
    # Be sure to return status code 303 to avoid a double DELETE:
    # http://api.rubyonrails.org/classes/ActionController/Redirecting.html
    redirect_to project_path(@project), status: 303 if @project.empty_repo?
  end

  def require_branch_head
    unless @repository.branch_exists?(@ref)
      redirect_to(
        project_tree_path(@project, @ref),
        notice: "This action is not allowed unless you are on a branch"
      )
    end
  end

  def apply_diff_view_cookie!
    cookies.permanent[:diff_view] = params.delete(:view) if params[:view].present?
  end

  def require_pages_enabled!
    not_found unless @project.pages_available?
  end

  def check_issues_available!
    return render_404 unless @project.feature_available?(:issues, current_user)
  end

  def user_access(project)
    @user_access ||= {}
    @user_access[project] ||= Gitlab::UserAccess.new(current_user, project: project)
  end
end
