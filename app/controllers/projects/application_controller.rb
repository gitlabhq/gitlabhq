class Projects::ApplicationController < ApplicationController
  skip_before_action :authenticate_user!
  before_action :project
  before_action :repository
  layout 'project'

  helper_method :repository, :can_collaborate_with_project?

  private

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
        redirect_to request.original_url.gsub(/\.git\/?\Z/, '')
        return
      end

      project_path = "#{namespace}/#{id}"
      @project = Project.find_with_namespace(project_path)

      if can?(current_user, :read_project, @project) && !@project.pending_delete?
        if @project.path_with_namespace != project_path
          redirect_to request.original_url.gsub(project_path, @project.path_with_namespace)
        end
      else
        @project = nil

        if current_user.nil?
          authenticate_user!
        else
          render_404
        end
      end
    end

    @project
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
    @show_changes_tab = params[:view].present?
    cookies.permanent[:diff_view] = params.delete(:view) if params[:view].present?
  end

  def builds_enabled
    return render_404 unless @project.feature_available?(:builds, current_user)
  end
end
