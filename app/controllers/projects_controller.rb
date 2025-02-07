# frozen_string_literal: true

class ProjectsController < Projects::ApplicationController
  include API::Helpers::RelatedResourcesHelpers
  include IssuableCollections
  include PreviewMarkdown
  include SendFileUpload
  include RecordUserLastActivity
  include ImportUrlParams
  include FiltersEvents
  include SourcegraphDecorator

  REFS_LIMIT = 100

  prepend_before_action(only: [:show]) { authenticate_sessionless_user!(:rss) }

  around_action :allow_gitaly_ref_name_caching, only: [:index, :show]

  before_action :disable_query_limiting, only: [:show, :create]
  before_action :authenticate_user!, except: [:index, :show, :activity, :refs, :unfoldered_environment_names]
  before_action :redirect_git_extension, only: [:show]
  before_action :project, except: [:index, :new, :create]
  before_action :repository, except: [:index, :new, :create]
  before_action :verify_git_import_enabled, only: [:create]
  before_action :project_export_enabled, only: [:export, :download_export, :remove_export, :generate_new_export]
  before_action :present_project, only: [:edit]
  before_action :authorize_read_code!, only: [:refs]

  # Authorize
  before_action :authorize_view_edit_page!, only: :edit
  before_action :authorize_admin_project!, only: [:update, :housekeeping, :download_export, :export, :remove_export, :generate_new_export]
  before_action :authorize_archive_project!, only: [:archive, :unarchive]
  before_action :event_filter, only: [:show, :activity]

  # Project Export Rate Limit
  before_action :check_export_rate_limit!, only: [:export, :download_export, :generate_new_export]

  before_action do
    push_frontend_feature_flag(:inline_blame, @project)
    push_frontend_feature_flag(:remove_monitor_metrics, @project)
    push_frontend_feature_flag(:issue_email_participants, @project)
    push_frontend_feature_flag(:edit_branch_rules, @project)
    # TODO: We need to remove the FF eventually when we rollout page_specific_styles
    push_frontend_feature_flag(:page_specific_styles, current_user)
    push_frontend_feature_flag(:blob_repository_vue_header_app, @project)
    push_frontend_feature_flag(:blob_overflow_menu, current_user)
    push_licensed_feature(:file_locks) if @project.present? && @project.licensed_feature_available?(:file_locks)
    push_frontend_feature_flag(:directory_code_dropdown_updates, current_user)

    if @project.present? && @project.licensed_feature_available?(:security_orchestration_policies)
      push_licensed_feature(:security_orchestration_policies)
    end

    push_force_frontend_feature_flag(:work_items, @project&.work_items_feature_flag_enabled?)
    push_force_frontend_feature_flag(:work_items_beta, @project&.work_items_beta_feature_flag_enabled?)
    push_force_frontend_feature_flag(:work_items_alpha, @project&.work_items_alpha_feature_flag_enabled?)
    push_frontend_feature_flag(:work_item_description_templates, @project&.group)
  end

  layout :determine_layout

  feature_category :groups_and_projects, [
    :index, :show, :new, :create, :edit, :update, :transfer,
    :destroy, :archive, :unarchive, :toggle_star, :activity
  ]

  feature_category :source_code_management, [:remove_fork, :housekeeping, :refs]
  feature_category :team_planning, [:preview_markdown, :new_issuable_address]
  feature_category :importers, [:export, :remove_export, :generate_new_export, :download_export]
  feature_category :code_review_workflow, [:unfoldered_environment_names]

  urgency :low, [:export, :remove_export, :generate_new_export, :download_export]
  urgency :low, [:preview_markdown, :new_issuable_address]
  # TODO: Set high urgency for #show https://gitlab.com/gitlab-org/gitlab/-/issues/334444

  urgency :low, [:refs, :show, :toggle_star, :transfer, :archive, :destroy, :update, :create,
    :activity, :edit, :new, :export, :remove_export, :generate_new_export, :download_export]

  urgency :high, [:unfoldered_environment_names]

  def index
    redirect_to(current_user ? root_path : explore_root_path)
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def new
    @namespace = Namespace.find_by(id: params[:namespace_id]) if params[:namespace_id]
    return access_denied! if @namespace && !can?(current_user, :create_projects, @namespace)

    @parent_group = Group.find_by(id: params[:namespace_id])

    manageable_groups = ::Groups::AcceptingProjectCreationsFinder.new(current_user).execute.limit(2)

    return access_denied! if manageable_groups.empty? && !can?(current_user, :create_projects, current_user.namespace)

    @current_user_group = manageable_groups.first if manageable_groups.one?

    @project = Project.new(namespace_id: @namespace&.id)
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def edit
    @badge_api_endpoint = expose_path(api_v4_projects_badges_path(id: @project.id))
    render_edit
  end

  def create
    @project = ::Projects::CreateService.new(current_user, project_params(attributes: project_params_create_attributes)).execute

    if @project.saved?
      redirect_to(
        project_path(@project, custom_import_params),
        notice: _("Project '%{project_name}' was successfully created.") % { project_name: @project.name }
      )
    else
      render 'new'
    end
  end

  def update
    result = ::Projects::UpdateService.new(@project, current_user, project_params).execute

    # Refresh the repo in case anything changed
    @repository = @project.repository

    handle_update_result(result)
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def transfer
    return access_denied! unless can?(current_user, :change_namespace, @project)

    namespace = Namespace.find_by(id: params[:new_namespace_id])
    ::Projects::TransferService.new(project, current_user).execute(namespace)

    if @project.errors[:new_namespace].present?
      flash[:alert] = @project.errors[:new_namespace].first
      return redirect_to edit_project_path(@project)
    end

    redirect_to edit_project_path(@project)
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def remove_fork
    return access_denied! unless can?(current_user, :remove_fork_project, @project)

    if ::Projects::UnlinkForkService.new(@project, current_user).execute
      flash[:notice] = _('The fork relationship has been removed.')
    end

    redirect_to edit_project_path(@project)
  end

  def activity
    respond_to do |format|
      format.html
      format.json do
        load_events
        pager_json('events/_events', @events.count { |event| event.visible_to_user?(current_user) })
      end
    end
  end

  def show
    @id = @ref = repository_root
    @path = ''

    if @project.import_in_progress?
      redirect_to project_import_path(@project, custom_import_params)
      return
    end

    if @project.pending_delete?
      flash.now[:alert] = _("Project '%{project_name}' queued for deletion.") % { project_name: @project.name }
    end

    @ref_type = 'heads'

    respond_to do |format|
      format.html do
        @project = @project.present(current_user: current_user)
        render_landing_page
      end

      format.atom do
        load_events
        @events = @events.select { |event| event.visible_to_user?(current_user) }
        render layout: 'xml'
      end
    end
  end

  def destroy
    return access_denied! unless can?(current_user, :remove_project, @project)

    ::Projects::DestroyService.new(@project, current_user, {}).async_execute
    flash[:toast] = format(_("Project '%{project_name}' is being deleted."), project_name: @project.full_name)

    redirect_to dashboard_projects_path, status: :found
  rescue Projects::DestroyService::DestroyError => e
    redirect_to edit_project_path(@project), status: :found, alert: e.message
  end

  def new_issuable_address
    return render_404 unless Gitlab::Email::IncomingEmail.supports_issue_creation?

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
    task = if params[:prune].present?
             :prune
           else
             :eager
           end

    ::Repositories::HousekeepingService.new(@project, task).execute do
      ::Gitlab::Audit::Auditor.audit(
        name: 'manually_trigger_housekeeping',
        author: current_user,
        scope: @project,
        target: @project,
        message: "Housekeeping task: #{task}",
        created_at: DateTime.current
      )
    end

    redirect_to(
      project_path(@project),
      notice: _("Housekeeping successfully started")
    )
  rescue ::Repositories::HousekeepingService::LeaseTaken => e
    redirect_to(
      edit_project_path(@project, anchor: 'js-project-advanced-settings'),
      alert: e.to_s
    )
  end

  def export
    @project.add_export_job(current_user: current_user)

    redirect_to(
      edit_project_path(@project, anchor: 'js-project-advanced-settings'),
      notice: _("Project export started. A download link will be sent by email and made available on this page.")
    )
  rescue Project::ExportLimitExceeded => e
    redirect_to(
      edit_project_path(@project, anchor: 'js-project-advanced-settings'),
      alert: e.to_s
    )
  end

  def download_export
    if @project.export_file_exists?(current_user)
      if @project.export_archive_exists?(current_user)
        export_file = @project.export_file(current_user)
        send_upload(export_file, attachment: export_file.filename)
      else
        redirect_to(
          edit_project_path(@project, anchor: 'js-project-advanced-settings'),
          alert: _("The file containing the export is not available yet; it may still be transferring. Please try again later.")
        )
      end
    else
      redirect_to(
        edit_project_path(@project, anchor: 'js-project-advanced-settings'),
        alert: _("Project export link has expired. Please generate a new export from your project settings.")
      )
    end
  end

  def remove_export
    if @project.remove_export_for_user(current_user)
      flash[:notice] = _("Project export has been deleted.")
    else
      flash[:alert] = _("Project export could not be deleted.")
    end

    redirect_to(edit_project_path(@project, anchor: 'js-project-advanced-settings'))
  end

  def generate_new_export
    if @project.remove_export_for_user(current_user)
      export
    else
      redirect_to(
        edit_project_path(@project, anchor: 'js-project-advanced-settings'),
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
    find_refs = refs_params['find']

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
      branches = BranchesFinder.new(@repository, refs_params.merge(per_page: REFS_LIMIT))
                   .execute(gitaly_pagination: true)
                   .take(REFS_LIMIT)
                   .map(&:name)

      options['Branches'] = branches
    end

    if find_tags && @repository.tag_count.nonzero?
      tags = TagsFinder.new(@repository, refs_params.merge(per_page: REFS_LIMIT))
               .execute(gitaly_pagination: true)
               .take(REFS_LIMIT)
               .map(&:name)

      options['Tags'] = tags
    end

    # If reference is commit id - we should add it to branch/tag selectbox
    ref = Addressable::URI.unescape(refs_params[:ref])
    if find_commits && ref && options.flatten(2).exclude?(ref) && ref =~ /\A[0-9a-zA-Z]{6,52}\z/
      options['Commits'] = [ref]
    end

    render json: Gitlab::Json.dump(options)
  rescue Gitlab::Git::CommandError
    render json: { error: _('Unable to load refs') }, status: :service_unavailable
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def unfoldered_environment_names
    respond_to do |format|
      format.json do
        render json: Environments::EnvironmentNamesFinder.new(@project, current_user).execute
      end
    end
  end

  private

  def refs_params
    params.permit(:search, :sort, :ref, find: [])
  end

  # Render project landing depending of which features are available
  # So if page is not available in the list it renders the next page
  #
  # pages list order: repository readme, wiki home, issues list, customize workflow
  def render_landing_page
    Gitlab::Tracking.event('project_overview', 'render', user: current_user, project: @project.project)

    if can?(current_user, :read_code, @project)
      return render 'projects/no_repo' unless @project.repository_exists?
      return render 'projects/missing_default_branch', status: :service_unavailable if @ref == ''

      render 'projects/empty' if @project.empty_repo?
    else
      if can?(current_user, :read_wiki, @project)
        @wiki = @project.wiki
        @wiki_home = @wiki.find_page('home', params[:version_id])
      elsif @project.feature_available?(:issues, current_user)
        @issues = issuables_collection.page(params[:page])
        @issuable_meta_data = Gitlab::IssuableMetadata.new(current_user, @issues).data
      end

      render :show
    end
  end

  def finder_type
    IssuesFinder
  end

  def determine_layout
    if [:new, :create].include?(action_name.to_sym)
      'dashboard'
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
      .map(&:present)
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def project_params(attributes: [])
    params.require(:project)
      .permit(project_params_attributes + attributes)
      .merge(import_url_params)
      .merge(object_format_params)
  end

  def project_feature_attributes
    %i[
      builds_access_level
      issues_access_level
      forking_access_level
      merge_requests_access_level
      repository_access_level
      snippets_access_level
      wiki_access_level
      package_registry_access_level
      pages_access_level
      metrics_dashboard_access_level
      analytics_access_level
      security_and_compliance_access_level
      container_registry_access_level
      releases_access_level
      environments_access_level
      feature_flags_access_level
      monitor_access_level
      infrastructure_access_level
      model_experiments_access_level
      model_registry_access_level
    ]
  end

  def project_setting_attributes
    %i[
      show_default_award_emojis
      show_diff_preview_in_email
      squash_option
      mr_default_target_self
      warn_about_potentially_unwanted_characters
      enforce_auth_checks_on_uploads
      emails_enabled
    ]
  end

  def project_params_attributes
    [
      :allow_merge_on_skipped_pipeline,
      :avatar,
      :build_allow_git_fetch,
      :build_timeout_human_readable,
      :resolve_outdated_diff_discussions,
      :container_registry_enabled,
      :description,
      :external_authorization_classification_label,
      :import_url,
      :issues_tracker,
      :issues_tracker_id,
      :last_activity_at,
      :lfs_enabled,
      :name,
      :only_allow_merge_if_all_discussions_are_resolved,
      :only_allow_merge_if_pipeline_succeeds,
      :allow_merge_without_pipeline,
      :path,
      :printing_merge_request_link_enabled,
      :public_builds,
      :remove_source_branch_after_merge,
      :request_access_enabled,
      :runners_token,
      :tag_list,
      :topics,
      :visibility_level,
      :template_name,
      :template_project_id,
      :merge_method,
      :initialize_with_sast,
      :initialize_with_readme,
      :ci_separated_caches,
      :suggestion_commit_message,
      :packages_enabled,
      :service_desk_enabled,
      :merge_commit_template_or_default,
      :squash_commit_template_or_default,
      { project_setting_attributes: project_setting_attributes,
        project_feature_attributes: project_feature_attributes }
    ]
  end

  def project_params_create_attributes
    [:namespace_id]
  end

  def custom_import_params
    {}
  end

  def object_format_params
    return {} unless Gitlab::Utils.to_boolean(params.dig(:project, :use_sha256_repository))

    { repository_object_format: Repository::FORMAT_SHA256 }
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

  def repository_root
    project.repository.root_ref
  rescue Gitlab::Git::CommandError
    # Empty string is intentional and prevent the @ref reload
    ''
  end

  def build_canonical_path(project)
    params[:namespace_id] = project.namespace.to_param
    params[:id] = project.to_param

    url_for(safe_params)
  end

  def verify_git_import_enabled
    render_404 if project_params[:import_url] && !git_import_enabled?
  end

  def project_export_enabled
    render_404 unless Gitlab::CurrentSettings.project_export_enabled?
  end

  # Redirect from localhost/group/project.git to localhost/group/project
  def redirect_git_extension
    return unless params[:format] == 'git'

    # `project` calls `find_routable!`, so this will trigger the usual not-found
    # behaviour when the user isn't authorized to see the project
    return if project.nil? || performed?

    uri = URI(request.original_url)
    # Strip the '.git' part from the path
    uri.path = uri.path.sub(%r{\.git/?\Z}, '')

    redirect_to(uri.to_s)
  end

  def disable_query_limiting
    Gitlab::QueryLimiting.disable!('https://gitlab.com/gitlab-org/gitlab/-/issues/20826')
  end

  def present_project
    @project = @project.present(current_user: current_user)
  end

  def check_export_rate_limit!
    prefixed_action = "project_#{params[:action]}".to_sym

    group_scope = params[:action] == 'download_export' ? @project.namespace : nil

    check_rate_limit!(prefixed_action, scope: [current_user, group_scope].compact)
  end

  def render_edit
    render 'edit'
  end
end

ProjectsController.prepend_mod_with('ProjectsController')
