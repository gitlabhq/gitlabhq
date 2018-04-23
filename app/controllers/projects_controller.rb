class ProjectsController < Projects::ApplicationController
  include IssuableCollections
  include ExtractsPath
  include PreviewMarkdown

  before_action :whitelist_query_limiting, only: [:create]
  before_action :authenticate_user!, except: [:index, :show, :activity, :refs]
  before_action :redirect_git_extension, only: [:show]
  before_action :project, except: [:index, :new, :create]
  before_action :repository, except: [:index, :new, :create]
  before_action :assign_ref_vars, only: [:show], if: :repo_exists?
  before_action :tree, only: [:show], if: [:repo_exists?, :project_view_files?]
  before_action :lfs_blob_ids, only: [:show], if: [:repo_exists?, :project_view_files?]
  before_action :project_export_enabled, only: [:export, :download_export, :remove_export, :generate_new_export]

  # Authorize
  before_action :authorize_admin_project!, only: [:edit, :update, :housekeeping, :download_export, :export, :remove_export, :generate_new_export]
  before_action :event_filter, only: [:show, :activity]

  layout :determine_layout

  def index
    redirect_to(current_user ? root_path : explore_root_path)
  end

  def new
    namespace = Namespace.find_by(id: params[:namespace_id]) if params[:namespace_id]
    return access_denied! if namespace && !can?(current_user, :create_projects, namespace)

    @project = Project.new(namespace_id: namespace&.id)
  end

  def edit
    render 'edit'
  end

  def create
    @project = ::Projects::CreateService.new(current_user, project_params).execute

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
          redirect_to(edit_project_path(@project))
        end
      else
        flash[:alert] = result[:message]

        format.html { render 'edit' }
      end

      format.js
    end
  end

  def transfer
    return access_denied! unless can?(current_user, :change_namespace, @project)

    namespace = Namespace.find_by(id: params[:new_namespace_id])
    ::Projects::TransferService.new(project, current_user).execute(namespace)

    if @project.errors[:new_namespace].present?
      flash[:alert] = @project.errors[:new_namespace].first
    end
  end

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

    redirect_to dashboard_projects_path, status: 302
  rescue Projects::DestroyService::DestroyError => ex
    redirect_to edit_project_path(@project), status: 302, alert: ex.message
  end

  def new_issuable_address
    return render_404 unless Gitlab::IncomingEmail.supports_issue_creation?

    current_user.reset_incoming_email_token!
    render json: { new_address: @project.new_issuable_address(current_user, params[:issuable_type]) }
  end

  def archive
    return access_denied! unless can?(current_user, :archive_project, @project)

    @project.archive!

    respond_to do |format|
      format.html { redirect_to project_path(@project) }
    end
  end

  def unarchive
    return access_denied! unless can?(current_user, :archive_project, @project)

    @project.unarchive!

    respond_to do |format|
      format.html { redirect_to project_path(@project) }
    end
  end

  def housekeeping
    ::Projects::HousekeepingService.new(@project).execute

    redirect_to(
      project_path(@project),
      notice: _("Housekeeping successfully started")
    )
  rescue ::Projects::HousekeepingService::LeaseTaken => ex
    redirect_to(
      edit_project_path(@project),
      alert: ex.to_s
    )
  end

  def export
    @project.add_export_job(current_user: current_user)

    redirect_to(
      edit_project_path(@project),
      notice: _("Project export started. A download link will be sent by email.")
    )
  end

  def download_export
    export_project_path = @project.export_project_path

    if export_project_path
      send_file export_project_path, disposition: 'attachment'
    else
      redirect_to(
        edit_project_path(@project),
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

    redirect_to(edit_project_path(@project))
  end

  def generate_new_export
    if @project.remove_exports
      export
    else
      redirect_to(
        edit_project_path(@project),
        alert: _("Project export could not be deleted.")
      )
    end
  end

  def toggle_star
    current_user.toggle_star(@project)
    @project.reload

    render json: {
      star_count: @project.star_count
    }
  end

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
      options[s_('RefSwitcher|Branches')] = branches
    end

    if find_tags && @repository.tag_count.nonzero?
      tags = TagsFinder.new(@repository, params).execute.take(100).map(&:name)

      options[s_('RefSwitcher|Tags')] = tags
    end

    # If reference is commit id - we should add it to branch/tag selectbox
    ref = Addressable::URI.unescape(params[:ref])
    if find_commits && ref && options.flatten(2).exclude?(ref) && ref =~ /\A[0-9a-zA-Z]{6,52}\z/
      options['Commits'] = [ref]
    end

    render json: options.to_json
  end

  private

  # Render project landing depending of which features are available
  # So if page is not availble in the list it renders the next page
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
        @issuable_meta_data = issuable_meta_data(@issues, @collection_type)
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

  def load_events
    projects = Project.where(id: @project.id)

    @events = EventCollection
      .new(projects, offset: params[:offset].to_i, filter: event_filter)
      .to_a

    Events::RenderService.new(current_user).execute(@events, atom_request: request.format.atom?)
  end

  def project_params
    params.require(:project)
      .permit(project_params_attributes)
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
      :import_url,
      :issues_tracker,
      :issues_tracker_id,
      :last_activity_at,
      :lfs_enabled,
      :name,
      :namespace_id,
      :only_allow_merge_if_all_discussions_are_resolved,
      :only_allow_merge_if_pipeline_succeeds,
      :printing_merge_request_link_enabled,
      :path,
      :public_builds,
      :request_access_enabled,
      :runners_token,
      :tag_list,
      :visibility_level,
      :template_name,
      :merge_method,

      project_feature_attributes: %i[
        builds_access_level
        issues_access_level
        merge_requests_access_level
        repository_access_level
        snippets_access_level
        wiki_access_level
      ]
    ]
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
    Gitlab::QueryLimiting.whitelist('https://gitlab.com/gitlab-org/gitlab-ce/issues/42440')
  end
end
