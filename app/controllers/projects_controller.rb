# frozen_string_literal: true

class ProjectsController < Projects::ApplicationController
  include API::Helpers::RelatedResourcesHelpers
  include IssuableCollections
  include ExtractsPath
  include PreviewMarkdown
  include SendFileUpload
  include RecordUserLastActivity
  include ImportUrlParams

  prepend_before_action(only: [:show]) { authenticate_sessionless_user!(:rss) }

  around_action :allow_gitaly_ref_name_caching, only: [:index, :show]

  before_action :whitelist_query_limiting, only: [:create]
  before_action :authenticate_user!, except: [:index, :show, :activity, :refs, :resolve]
  before_action :redirect_git_extension, only: [:show]
  before_action :project, except: [:index, :new, :create, :resolve]
  before_action :repository, except: [:index, :new, :create, :resolve]
  before_action :assign_ref_vars, if: -> { action_name == 'show' && repo_exists? }
  before_action :tree,
    if: -> { action_name == 'show' && repo_exists? && project_view_files? }
  before_action :lfs_blob_ids, if: :show_blob_ids?, only: :show
  before_action :project_export_enabled, only: [:export, :download_export, :remove_export, :generate_new_export]
  before_action :present_project, only: [:edit]
  before_action :authorize_download_code!, only: [:refs]

  # Authorize
  before_action :authorize_admin_project!, only: [:edit, :update, :housekeeping, :download_export, :export, :remove_export, :generate_new_export]
  before_action :authorize_archive_project!, only: [:archive, :unarchive]
  before_action :event_filter, only: [:show, :activity]

  # Project Export Rate Limit
  before_action :export_rate_limit, only: [:export, :download_export, :generate_new_export]

  layout :determine_layout

  def index
    redirect_to(current_user ? root_path : explore_root_path)
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def new
    @namespace = Namespace.find_by(id: params[:namespace_id]) if params[:namespace_id]
    return access_denied! if @namespace && !can?(current_user, :create_projects, @namespace)

    @project = Project.new(namespace_id: @namespace&.id)
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def edit
    @badge_api_endpoint = expose_url(api_v4_projects_badges_path(id: @project.id))
    render 'edit'
  end

  def create
    @project = ::Projects::CreateService.new(current_user, project_params(attributes: project_params_create_attributes)).execute

    if @project.saved?
      cookies[:issue_board_welcome_hidden] = { path: project_path(@project), value: nil, expires: Time.at(0) }

      redirect_to(
        project_path(@project, custom_import_params),
        notice: _("Project '%{project_name}' was successfully created.") % { project_name: @project.name }
      )
    else
      render 'new', locals: { active_tab: active_new_project_tab }
    end
  end

  def update
    result = ::Projects::UpdateService.new(@project, current_user, project_params).execute

    # Refresh the repo in case anything changed
    @repository = @project.repository

    respond_to do |format|
      if result[:status] == :success
        flash[:notice] = _("Project '%{project_name}' was successfully updated.") % { project_name: @project.name }

        format.html do
          redirect_to(edit_project_path(@project, anchor: 'js-general-project-settings'))
        end
      else
        flash.now[:alert] = result[:message]

        format.html { render 'edit' }
      end

      format.js
    end
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def transfer
    return access_denied! unless can?(current_user, :change_namespace, @project)

    namespace = Namespace.find_by(id: params[:new_namespace_id])
    ::Projects::TransferService.new(project, current_user).execute(namespace)

    if @project.errors[:new_namespace].present?
      flash[:alert] = @project.errors[:new_namespace].first
    end
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def remove_fork
    return access_denied! unless can?(current_user, :remove_fork_project, @project)

    if ::Projects::UnlinkForkService.new(@project, current_user).execute
      flash[:notice] = _('The fork relationship has been removed.')
    end
  end

  def activity
    respond_to do |format|
      format.html
      format.json do
        load_events
        pager_json('events/_events', @events.count)
      end
    end
  end

  def show
    if @project.import_in_progress?
      redirect_to project_import_path(@project, custom_import_params)
      return
    end

    if @project.pending_delete?
      flash.now[:alert] = _("Project '%{project_name}' queued for deletion.") % { project_name: @project.name }
    end

    respond_to do |format|
      format.html do
        @notification_setting = current_user.notification_settings_for(@project) if current_user
        @project = @project.present(current_user: current_user)

        render_landing_page
      end

      format.atom do
        load_events
        render layout: 'xml.atom'
      end
    end
  end

  def destroy
    return access_denied! unless can?(current_user, :remove_project, @project)

    ::Projects::DestroyService.new(@project, current_user, {}).async_execute
    flash[:notice] = _("Project '%{project_name}' is in the process of being deleted.") % { project_name: @project.full_name }

    redirect_to dashboard_projects_path, status: :found
  rescue Projects::DestroyService::DestroyError => ex
    redirect_to edit_project_path(@project), status: :found, alert: ex.message
  end

  def new_issuable_address
    return render_404 unless Gitlab::IncomingEmail.supports_issue_creation?

    current_user.reset_incoming_email_token!
    render json: { new_address: @project.new_issuable_address(current_user, params[:issuable_type]) }
  end

  def archive
    ::Projects::UpdateService.new(@project, current_user, archived: true).execute

    respond_to do |format|
      format.html { redirect_to project_path(@project) }
    end
  end

  def unarchive
    ::Projects::UpdateService.new(@project, current_user, archived: false).execute

    respond_to do |format|
      format.html { redirect_to project_path(@project) }
    end
  end

  def housekeeping
    ::Projects::HousekeepingService.new(@project, :gc).execute

    redirect_to(
      project_path(@project),
      notice: _("Housekeeping successfully started")
    )
  rescue ::Projects::HousekeepingService::LeaseTaken => ex
    redirect_to(
      edit_project_path(@project, anchor: 'js-project-advanced-settings'),
      alert: ex.to_s
    )
  end

  def export
    @project.add_export_job(current_user: current_user)

    redirect_to(
      edit_project_path(@project, anchor: 'js-export-project'),
      notice: _("Project export started. A download link will be sent by email.")
    )
  end

  def download_export
    if @project.export_file_exists?
      send_upload(@project.export_file, attachment: @project.export_file.filename)
    else
      redirect_to(
        edit_project_path(@project, anchor: 'js-export-project'),
        alert: _("Project export link has expired. Please generate a new export from your project settings.")
      )
    end
  end

  def remove_export
    if @project.remove_exports
      flash[:notice] = _("Project export has been deleted.")
    else
      flash[:alert] = _("Project export could not be deleted.")
    end

    redirect_to(edit_project_path(@project, anchor: 'js-export-project'))
  end

  def generate_new_export
    if @project.remove_exports
      export
    else
      redirect_to(
        edit_project_path(@project, anchor: 'js-export-project'),
        alert: _("Project export could not be deleted.")
      )
    end
  end

  def toggle_star
    current_user.toggle_star(@project)
    @project.reset

    render json: {
      star_count: @project.star_count
    }
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def refs
    find_refs = params['find']

    find_branches = true
    find_tags = true
    find_commits = true

    unless find_refs.nil?
      find_branches = find_refs.include?('branches')
      find_tags = find_refs.include?('tags')
      find_commits = find_refs.include?('commits')
    end

    options = {}

    if find_branches
      branches = BranchesFinder.new(@repository, params).execute.take(100).map(&:name)
      options['Branches'] = branches
    end

    if find_tags && @repository.tag_count.nonzero?
      tags = TagsFinder.new(@repository, params).execute.take(100).map(&:name)

      options['Tags'] = tags
    end

    # If reference is commit id - we should add it to branch/tag selectbox
    ref = Addressable::URI.unescape(params[:ref])
    if find_commits && ref && options.flatten(2).exclude?(ref) && ref =~ /\A[0-9a-zA-Z]{6,52}\z/
      options['Commits'] = [ref]
    end

    render json: options.to_json
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def resolve
    @project = Project.find(params[:id])

    if can?(current_user, :read_project, @project)
      redirect_to @project
    else
      render_404
    end
  end

  private

  def show_blob_ids?
    repo_exists? && project_view_files? && Feature.disabled?(:vue_file_list, @project)
  end

  # Render project landing depending of which features are available
  # So if page is not available in the list it renders the next page
  #
  # pages list order: repository readme, wiki home, issues list, customize workflow
  def render_landing_page
    if can?(current_user, :download_code, @project)
      return render 'projects/no_repo' unless @project.repository_exists?

      render 'projects/empty' if @project.empty_repo?
    else
      if can?(current_user, :read_wiki, @project)
        @project_wiki = @project.wiki
        @wiki_home = @project_wiki.find_page('home', params[:version_id])
      elsif @project.feature_available?(:issues, current_user)
        @issues = issuables_collection.page(params[:page])
        @collection_type = 'Issue'
        @issuable_meta_data = issuable_meta_data(@issues, @collection_type, current_user)
      end

      render :show
    end
  end

  def finder_type
    IssuesFinder
  end

  def determine_layout
    if [:new, :create].include?(action_name.to_sym)
      'application'
    elsif [:edit, :update].include?(action_name.to_sym)
      'project_settings'
    else
      'project'
    end
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def load_events
    projects = Project.where(id: @project.id)

    @events = EventCollection
      .new(projects, offset: params[:offset].to_i, filter: event_filter)
      .to_a

    Events::RenderService.new(current_user).execute(@events, atom_request: request.format.atom?)
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def project_params(attributes: [])
    params.require(:project)
      .permit(project_params_attributes + attributes)
      .merge(import_url_params)
  end

  def project_params_attributes
    [
      :avatar,
      :build_allow_git_fetch,
      :build_coverage_regex,
      :build_timeout_human_readable,
      :resolve_outdated_diff_discussions,
      :container_registry_enabled,
      :default_branch,
      :description,
      :emails_disabled,
      :external_authorization_classification_label,
      :import_url,
      :issues_tracker,
      :issues_tracker_id,
      :last_activity_at,
      :lfs_enabled,
      :name,
      :only_allow_merge_if_all_discussions_are_resolved,
      :only_allow_merge_if_pipeline_succeeds,
      :path,
      :printing_merge_request_link_enabled,
      :public_builds,
      :remove_source_branch_after_merge,
      :request_access_enabled,
      :runners_token,
      :tag_list,
      :visibility_level,
      :template_name,
      :template_project_id,
      :merge_method,
      :initialize_with_readme,

      project_feature_attributes: %i[
        builds_access_level
        issues_access_level
        merge_requests_access_level
        repository_access_level
        snippets_access_level
        wiki_access_level
        pages_access_level
      ]
    ]
  end

  def project_params_create_attributes
    [:namespace_id]
  end

  def custom_import_params
    {}
  end

  def active_new_project_tab
    project_params[:import_url].present? ? 'import' : 'blank'
  end

  def repo_exists?
    project.repository_exists? && !project.empty_repo?

  rescue Gitlab::Git::Repository::NoRepository
    project.repository.expire_exists_cache

    false
  end

  def project_view_files?
    if current_user
      current_user.project_view == 'files'
    else
      project_view_files_allowed?
    end
  end

  # Override extract_ref from ExtractsPath, which returns the branch and file path
  # for the blob/tree, which in this case is just the root of the default branch.
  # This way we avoid to access the repository.ref_names.
  def extract_ref(_id)
    [get_id, '']
  end

  # Override get_id from ExtractsPath in this case is just the root of the default branch.
  def get_id
    project.repository.root_ref
  end

  def project_view_files_allowed?
    !project.empty_repo? && can?(current_user, :download_code, project)
  end

  def build_canonical_path(project)
    params[:namespace_id] = project.namespace.to_param
    params[:id] = project.to_param

    url_for(safe_params)
  end

  def project_export_enabled
    render_404 unless Gitlab::CurrentSettings.project_export_enabled?
  end

  def redirect_git_extension
    # Redirect from
    #   localhost/group/project.git
    # to
    #   localhost/group/project
    #
    redirect_to request.original_url.sub(%r{\.git/?\Z}, '') if params[:format] == 'git'
  end

  def whitelist_query_limiting
    Gitlab::QueryLimiting.whitelist('https://gitlab.com/gitlab-org/gitlab-foss/issues/42440')
  end

  def present_project
    @project = @project.present(current_user: current_user)
  end

  def export_rate_limit
    prefixed_action = "project_#{params[:action]}".to_sym

    if rate_limiter.throttled?(prefixed_action, scope: [current_user, prefixed_action, @project])
      rate_limiter.log_request(request, "#{prefixed_action}_request_limit".to_sym, current_user)

      flash[:alert] = _('This endpoint has been requested too many times. Try again later.')
      redirect_to edit_project_path(@project)
    end
  end

  def rate_limiter
    ::Gitlab::ApplicationRateLimiter
  end
end

ProjectsController.prepend_if_ee('EE::ProjectsController')
