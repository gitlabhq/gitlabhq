# frozen_string_literal: true

class Projects::ApplicationController < ApplicationController
  include CookiesHelper
  include RoutableActions
  include ChecksCollaboration

  skip_before_action :authenticate_user!
  before_action :project
  before_action :repository
  layout 'project'

  before_action do
    push_namespace_setting(:math_rendering_limits_enabled, @project&.parent)
  end

  helper_method :repository, :can_collaborate_with_project?, :user_access

  rescue_from Gitlab::Template::Finders::RepoTemplateFinder::FileNotFoundError do |exception|
    log_exception(exception)
    render_404
  end

  private

  def project
    return @project if @project
    return unless params[:project_id] || params[:id]

    path = File.join(params[:namespace_id], params[:project_id] || params[:id])

    @project = find_routable!(Project, path, request.fullpath, extra_authorization_proc: auth_proc)
  end

  def auth_proc
    ->(project) { !project.pending_delete? }
  end

  def build_canonical_path(project)
    params[:namespace_id] = project.namespace.to_param
    params[:project_id] = project.to_param

    url_for(safe_params)
  end

  def repository
    @repository ||= project.repository
  end

  def authorize_action!(action)
    access_denied! unless can?(current_user, action, project)
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
      authorize_action!(Regexp.last_match(1).to_sym)
    when /\Acheck_(.*)_available!\z/
      check_project_feature_available!(Regexp.last_match(1).to_sym)
    else
      super
    end
  end

  def require_non_empty_project
    # Be sure to return status code 303 to avoid a double DELETE:
    # http://api.rubyonrails.org/classes/ActionController/Redirecting.html
    redirect_to project_path(@project), status: :see_other if @project.empty_repo?
  end

  def require_branch_head
    unless @repository.branch_exists?(@ref)
      redirect_to(
        project_tree_path(@project, @ref),
        notice: "This action is not allowed unless you are on a branch"
      )
    end
  end

  def require_pages_enabled!
    not_found unless ::Gitlab::Pages.enabled?
  end

  def check_issues_available!
    render_404 unless @project.feature_available?(:issues, current_user)
  end

  def set_is_ambiguous_ref
    return @is_ambiguous_ref if defined? @is_ambiguous_ref

    @is_ambiguous_ref = ExtractsRef::RequestedRef
                                                .new(@project.repository, ref_type: ref_type, ref: @ref)
                                                .find
                                                .fetch(:ambiguous, false)
  end

  def handle_update_result(result)
    if result[:status] == :success
      flash[:notice] = format(_("Project '%{project_name}' was successfully updated."), project_name: @project.name)
      redirect_to(edit_project_path(@project, anchor: 'js-general-project-settings'))
    else
      flash[:alert] = result[:message]
      @project.reset
      render 'edit'
    end
  end
end

Projects::ApplicationController.prepend_mod_with('Projects::ApplicationController')
