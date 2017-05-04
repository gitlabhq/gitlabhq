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
    if params[:format] == 'git'
      redirect_to request.original_url.gsub(/\.git\/?\Z/, '')
      return
    end
  end

  def project
    @project ||= find_routable!(Project, requested_full_path, extra_authorization_method: :project_not_being_deleted?)
  end

  def requested_full_path
    namespace = params[:namespace_id]
    id = params[:project_id] || params[:id]
    "#{namespace}/#{id}"
  end

  def project_not_being_deleted?(project)
    !project.pending_delete?
  end

  def repository
    @repository ||= project.repository
  end

  def can_collaborate_with_project?(project = nil)
    project ||= @project

    can?(current_user, :push_code, project) ||
      (current_user && current_user.already_forked?(project))
  end

  def authorize_project!(action)
    return access_denied! unless can?(current_user, action, project)
  end

  def method_missing(method_sym, *arguments, &block)
    if method_sym.to_s =~ /\Aauthorize_(.*)!\z/
      authorize_project!($1.to_sym)
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
