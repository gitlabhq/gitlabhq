# frozen_string_literal: true

module ProjectsHelper
  prepend_if_ee('::EE::ProjectsHelper') # rubocop: disable Cop/InjectEnterpriseEditionModule

  def link_to_project(project)
    link_to namespace_project_path(namespace_id: project.namespace, id: project), title: h(project.name) do
      title = content_tag(:span, project.name, class: 'project-name')

      if project.namespace
        namespace = content_tag(:span, "#{project.namespace.human_name} / ", class: 'namespace-name')
        title = namespace + title
      end

      title
    end
  end

  def link_to_member_avatar(author, opts = {})
    default_opts = { size: 16, lazy_load: false }
    opts = default_opts.merge(opts)

    classes = %W[avatar avatar-inline s#{opts[:size]}]
    classes << opts[:avatar_class] if opts[:avatar_class]

    avatar = avatar_icon_for_user(author, opts[:size])
    src = opts[:lazy_load] ? nil : avatar

    image_tag(src, width: opts[:size], class: classes, alt: '', "data-src" => avatar)
  end

  def author_content_tag(author, opts = {})
    default_opts = { author_class: 'author', tooltip: false, by_username: false }
    opts = default_opts.merge(opts)

    has_tooltip = !opts[:by_username] && opts[:tooltip]

    username = opts[:by_username] ? author.to_reference : author.name
    name_tag_options = { class: [opts[:author_class]] }

    if has_tooltip
      name_tag_options[:title] = author.to_reference
      name_tag_options[:data] = { placement: 'top' }
      name_tag_options[:class] << 'has-tooltip'
    end

    # NOTE: ActionView::Helpers::TagHelper#content_tag HTML escapes username
    content_tag(:span, username, name_tag_options)
  end

  def link_to_member(project, author, opts = {}, &block)
    default_opts = { avatar: true, name: true, title: ":name" }
    opts = default_opts.merge(opts)

    data_attrs = {
      user_id: author.id,
      username: author.username,
      name: author.name
    }

    return "(deleted)" unless author

    author_html = []

    # Build avatar image tag
    author_html << link_to_member_avatar(author, opts) if opts[:avatar]

    # Build name span tag
    author_html << author_content_tag(author, opts) if opts[:name]

    author_html << capture(&block) if block

    author_html = author_html.join.html_safe

    if opts[:name]
      link_to(author_html, user_path(author), class: "author-link js-user-link #{"#{opts[:extra_class]}" if opts[:extra_class]} #{"#{opts[:mobile_classes]}" if opts[:mobile_classes]}", data: data_attrs).html_safe
    else
      title = opts[:title].sub(":name", sanitize(author.name))
      link_to(author_html, user_path(author), class: "author-link has-tooltip", title: title, data: { container: 'body', qa_selector: 'assignee_link' }).html_safe
    end
  end

  def project_title(project)
    namespace_link =
      if project.group
        group_title(project.group, nil, nil)
      else
        owner = project.namespace.owner
        link_to(simple_sanitize(owner.name), user_path(owner))
      end

    project_link = link_to project_path(project) do
      icon = project_icon(project, alt: project.name, class: 'avatar-tile', width: 15, height: 15) if project.avatar_url && !Rails.env.test?
      [icon, content_tag("span", simple_sanitize(project.name), class: "breadcrumb-item-text js-breadcrumb-item-text")].join.html_safe
    end

    namespace_link = breadcrumb_list_item(namespace_link) unless project.group
    project_link = breadcrumb_list_item project_link

    "#{namespace_link} #{project_link}".html_safe
  end

  def remove_project_message(project)
    _("You are going to remove %{project_full_name}. Removed project CANNOT be restored! Are you ABSOLUTELY sure?") %
      { project_full_name: project.full_name }
  end

  def transfer_project_message(project)
    _("You are going to transfer %{project_full_name} to another owner. Are you ABSOLUTELY sure?") %
      { project_full_name: project.full_name }
  end

  def remove_fork_project_description_message(project)
    source = visible_fork_source(project)

    if source
      msg = _('This will remove the fork relationship between this project and %{fork_source}.') %
        { fork_source: link_to(source.full_name, project_path(source)) }

      msg.html_safe
    else
      _('This will remove the fork relationship between this project and other projects in the fork network.')
    end
  end

  def remove_fork_project_warning_message(project)
    _("You are going to remove the fork relationship from %{project_full_name}. Are you ABSOLUTELY sure?") %
      { project_full_name: project.full_name }
  end

  def visible_fork_source(project)
    project.fork_source if project.fork_source && can?(current_user, :read_project, project.fork_source)
  end

  def project_nav_tabs
    @nav_tabs ||= get_project_nav_tabs(@project, current_user)
  end

  def project_search_tabs?(tab)
    abilities = Array(search_tab_ability_map[tab])

    abilities.any? { |ability| can?(current_user, ability, @project) }
  end

  def project_nav_tab?(name)
    project_nav_tabs.include? name
  end

  def project_for_deploy_key(deploy_key)
    if deploy_key.has_access_to?(@project)
      @project
    else
      deploy_key.projects.find do |project|
        can?(current_user, :read_project, project)
      end
    end
  end

  def can_change_visibility_level?(project, current_user)
    return false unless can?(current_user, :change_visibility_level, project)

    if project.fork_source
      project.fork_source.visibility_level > Gitlab::VisibilityLevel::PRIVATE
    else
      true
    end
  end

  def can_disable_emails?(project, current_user)
    return false if project.group&.emails_disabled?

    can?(current_user, :set_emails_disabled, project)
  end

  def last_push_event
    current_user&.recent_push(@project)
  end

  def link_to_autodeploy_doc
    link_to _('About auto deploy'), help_page_path('autodevops/index.md#auto-deploy'), target: '_blank'
  end

  def autodeploy_flash_notice(branch_name)
    translation = _("Branch <strong>%{branch_name}</strong> was created. To set up auto deploy, choose a GitLab CI Yaml template and commit your changes. %{link_to_autodeploy_doc}") %
      { branch_name: truncate(sanitize(branch_name)), link_to_autodeploy_doc: link_to_autodeploy_doc }
    translation.html_safe
  end

  def project_list_cache_key(project, pipeline_status: true)
    key = [
      project.route.cache_key,
      project.cache_key,
      project.last_activity_date,
      controller.controller_name,
      controller.action_name,
      Gitlab::CurrentSettings.cache_key,
      "cross-project:#{can?(current_user, :read_cross_project)}",
      max_project_member_access_cache_key(project),
      pipeline_status,
      Gitlab::I18n.locale,
      'v2.6'
    ]

    key << pipeline_status_cache_key(project.pipeline_status) if pipeline_status && project.pipeline_status.has_status?

    key
  end

  def load_pipeline_status(projects)
    Gitlab::Cache::Ci::ProjectPipelineStatus
      .load_in_batch_for_projects(projects)
  end

  def show_no_ssh_key_message?
    Gitlab::CurrentSettings.user_show_add_ssh_key_message? &&
      cookies[:hide_no_ssh_message].blank? &&
      !current_user.hide_no_ssh_key &&
      current_user.require_ssh_key?
  end

  def show_no_password_message?
    cookies[:hide_no_password_message].blank? && !current_user.hide_no_password &&
      current_user.require_extra_setup_for_git_auth?
  end

  def show_auto_devops_implicitly_enabled_banner?(project, user)
    return false unless user_can_see_auto_devops_implicitly_enabled_banner?(project, user)

    cookies["hide_auto_devops_implicitly_enabled_banner_#{project.id}".to_sym].blank?
  end

  def link_to_set_password
    if current_user.require_password_creation_for_git?
      link_to s_('SetPasswordToCloneLink|set a password'), edit_profile_password_path
    else
      link_to s_('CreateTokenToCloneLink|create a personal access token'), profile_personal_access_tokens_path
    end
  end

  # Returns true if any projects are present.
  #
  # If the relation has a LIMIT applied we'll cast the relation to an Array
  # since repeated any? checks would otherwise result in multiple COUNT queries
  # being executed.
  #
  # If no limit is applied we'll just issue a COUNT since the result set could
  # be too large to load into memory.
  def any_projects?(projects)
    return projects.any? if projects.is_a?(Array)

    if projects.limit_value
      projects.to_a.any?
    else
      projects.except(:offset).any?
    end
  end

  # TODO: Remove this method when removing the feature flag
  # https://gitlab.com/gitlab-org/gitlab/merge_requests/11209#note_162234863
  # make sure to remove from the EE specific controller as well: ee/app/controllers/ee/dashboard/projects_controller.rb
  def show_projects?(projects, params)
    Feature.enabled?(:project_list_filter_bar) || !!(params[:personal] || params[:name] || any_projects?(projects))
  end

  def push_to_create_project_command(user = current_user)
    repository_url =
      if Gitlab::CurrentSettings.current_application_settings.enabled_git_access_protocol == 'http'
        user_url(user)
      else
        Gitlab.config.gitlab_shell.ssh_path_prefix + user.username
      end

    "git push --set-upstream #{repository_url}/$(git rev-parse --show-toplevel | xargs basename).git $(git rev-parse --abbrev-ref HEAD)"
  end

  def show_xcode_link?(project = @project)
    browser.platform.mac? && project.repository.xcode_project?
  end

  def xcode_uri_to_repo(project = @project)
    "xcode://clone?repo=#{CGI.escape(default_url_to_repo(project))}"
  end

  def link_to_bfg
    link_to 'BFG', 'https://rtyley.github.io/bfg-repo-cleaner/', target: '_blank', rel: 'noopener noreferrer'
  end

  def explore_projects_tab?
    current_page?(explore_projects_path) ||
      current_page?(trending_explore_projects_path) ||
      current_page?(starred_explore_projects_path)
  end

  def show_merge_request_count?(disabled: false, compact_mode: false)
    !disabled && !compact_mode && Feature.enabled?(:project_list_show_mr_count, default_enabled: true)
  end

  def show_issue_count?(disabled: false, compact_mode: false)
    !disabled && !compact_mode && Feature.enabled?(:project_list_show_issue_count, default_enabled: true)
  end

  # overridden in EE
  def settings_operations_available?
    can?(current_user, :read_environment, @project)
  end

  def error_tracking_setting_project_json
    setting = @project.error_tracking_setting

    return if setting.blank? || setting.project_slug.blank? ||
        setting.organization_slug.blank?

    {
      name: setting.project_name,
      organization_name: setting.organization_name,
      organization_slug: setting.organization_slug,
      slug: setting.project_slug
    }.to_json
  end

  def directory?
    @path.present?
  end

  def external_classification_label_help_message
    default_label = ::Gitlab::CurrentSettings.current_application_settings
                      .external_authorization_service_default_label

    s_(
      "ExternalAuthorizationService|When no classification label is set the "\
        "default label `%{default_label}` will be used."
    ) % { default_label: default_label }
  end

  def can_import_members?
    Ability.allowed?(current_user, :admin_project_member, @project)
  end

  def project_can_be_shared?
    !membership_locked? || @project.allowed_to_share_with_group?
  end

  def membership_locked?
    false
  end

  def share_project_description(project)
    share_with_group   = project.allowed_to_share_with_group?
    share_with_members = !membership_locked?

    description =
      if share_with_group && share_with_members
        _("You can invite a new member to <strong>%{project_name}</strong> or invite another group.")
      elsif share_with_group
        _("You can invite another group to <strong>%{project_name}</strong>.")
      elsif share_with_members
        _("You can invite a new member to <strong>%{project_name}</strong>.")
      end

    description.html_safe % { project_name: project.name }
  end

  def metrics_external_dashboard_url
    @project.metrics_setting_external_dashboard_url
  end

  def grafana_integration_url
    @project.grafana_integration&.grafana_url
  end

  def grafana_integration_token
    @project.grafana_integration&.token
  end

  def grafana_integration_enabled?
    @project.grafana_integration&.enabled?
  end

  private

  def get_project_nav_tabs(project, current_user)
    nav_tabs = [:home]

    unless project.empty_repo?
      nav_tabs << [:files, :commits, :network, :graphs, :forks] if can?(current_user, :download_code, project)
      nav_tabs << :releases if can?(current_user, :read_release, project)
    end

    if project.repo_exists? && can?(current_user, :read_merge_request, project)
      nav_tabs << :merge_requests
    end

    if Gitlab.config.registry.enabled && can?(current_user, :read_container_image, project)
      nav_tabs << :container_registry
    end

    # Pipelines feature is tied to presence of builds
    if can?(current_user, :read_build, project)
      nav_tabs << :pipelines
    end

    if can?(current_user, :read_environment, project) || can?(current_user, :read_cluster, project)
      nav_tabs << :operations
    end

    tab_ability_map.each do |tab, ability|
      if can?(current_user, ability, project)
        nav_tabs << tab
      end
    end

    nav_tabs << external_nav_tabs(project)

    nav_tabs.flatten
  end

  def external_nav_tabs(project)
    [].tap do |tabs|
      tabs << :external_issue_tracker if project.external_issue_tracker
      tabs << :external_wiki if project.external_wiki
    end
  end

  def tab_ability_map
    {
      environments:     :read_environment,
      milestones:       :read_milestone,
      snippets:         :read_project_snippet,
      settings:         :admin_project,
      builds:           :read_build,
      clusters:         :read_cluster,
      serverless:       :read_cluster,
      error_tracking:   :read_sentry_issue,
      labels:           :read_label,
      issues:           :read_issue,
      project_members:  :read_project_member,
      wiki:             :read_wiki
    }
  end

  def search_tab_ability_map
    @search_tab_ability_map ||= tab_ability_map.merge(
      blobs:          :download_code,
      commits:        :download_code,
      merge_requests: :read_merge_request,
      notes:          [:read_merge_request, :download_code, :read_issue, :read_project_snippet],
      members:        :read_project_member
    )
  end

  def project_lfs_status(project)
    if project.lfs_enabled?
      content_tag(:span, class: 'lfs-enabled') do
        s_('LFSStatus|Enabled')
      end
    else
      content_tag(:span, class: 'lfs-disabled') do
        s_('LFSStatus|Disabled')
      end
    end
  end

  def git_user_name
    if current_user
      current_user.name.gsub('"', '\"')
    else
      _("Your name")
    end
  end

  def git_user_email
    if current_user
      current_user.commit_email
    else
      "your@email.com"
    end
  end

  def default_url_to_repo(project = @project)
    case default_clone_protocol
    when 'ssh'
      project.ssh_url_to_repo
    else
      project.http_url_to_repo
    end
  end

  def default_clone_label
    _("Copy %{protocol} clone URL") % { protocol: default_clone_protocol.upcase }
  end

  def default_clone_protocol
    if allowed_protocols_present?
      enabled_protocol
    else
      extra_default_clone_protocol
    end
  end

  def extra_default_clone_protocol
    if !current_user || current_user.require_ssh_key?
      gitlab_config.protocol
    else
      'ssh'
    end
  end

  def sidebar_operations_link_path(project = @project)
    metrics_project_environments_path(project) if can?(current_user, :read_environment, project)
  end

  def project_last_activity(project)
    if project.last_activity_at
      time_ago_with_tooltip(project.last_activity_at, placement: 'bottom', html_class: 'last_activity_time_ago')
    else
      s_("ProjectLastActivity|Never")
    end
  end

  def project_wiki_path_with_version(proj, page, version, is_newest)
    url_params = is_newest ? {} : { version_id: version }
    project_wiki_path(proj, page, url_params)
  end

  def project_status_css_class(status)
    case status
    when "started"
      "table-active"
    when "failed"
      "table-danger"
    when "finished"
      "table-success"
    end
  end

  def readme_cache_key
    sha = @project.commit.try(:sha) || 'nil'
    [@project.full_path, sha, "readme"].join('-')
  end

  def current_ref
    @ref || @repository.try(:root_ref)
  end

  def project_child_container_class(view_path)
    view_path == "projects/issues/issues" ? "prepend-top-default" : "project-show-#{view_path}"
  end

  def project_issues(project)
    IssuesFinder.new(current_user, project_id: project.id).execute
  end

  def restricted_levels
    return [] if current_user.admin?

    Gitlab::CurrentSettings.restricted_visibility_levels || []
  end

  def project_permissions_settings(project)
    feature = project.project_feature
    {
      visibilityLevel: project.visibility_level,
      requestAccessEnabled: !!project.request_access_enabled,
      issuesAccessLevel: feature.issues_access_level,
      repositoryAccessLevel: feature.repository_access_level,
      mergeRequestsAccessLevel: feature.merge_requests_access_level,
      buildsAccessLevel: feature.builds_access_level,
      wikiAccessLevel: feature.wiki_access_level,
      snippetsAccessLevel: feature.snippets_access_level,
      pagesAccessLevel: feature.pages_access_level,
      containerRegistryEnabled: !!project.container_registry_enabled,
      lfsEnabled: !!project.lfs_enabled,
      emailsDisabled: project.emails_disabled?
    }
  end

  def project_permissions_panel_data(project)
    {
      currentSettings: project_permissions_settings(project),
      canDisableEmails: can_disable_emails?(project, current_user),
      canChangeVisibilityLevel: can_change_visibility_level?(project, current_user),
      allowedVisibilityOptions: project_allowed_visibility_levels(project),
      visibilityHelpPath: help_page_path('public_access/public_access'),
      registryAvailable: Gitlab.config.registry.enabled,
      registryHelpPath: help_page_path('user/packages/container_registry/index'),
      lfsAvailable: Gitlab.config.lfs.enabled,
      lfsHelpPath: help_page_path('workflow/lfs/manage_large_binaries_with_git_lfs'),
      pagesAvailable: Gitlab.config.pages.enabled,
      pagesAccessControlEnabled: Gitlab.config.pages.access_control,
      pagesAccessControlForced: ::Gitlab::Pages.access_control_is_forced?,
      pagesHelpPath: help_page_path('user/project/pages/introduction', anchor: 'gitlab-pages-access-control-core')
    }
  end

  def project_permissions_panel_data_json(project)
    project_permissions_panel_data(project).to_json.html_safe
  end

  def project_allowed_visibility_levels(project)
    Gitlab::VisibilityLevel.values.select do |level|
      project.visibility_level_allowed?(level) && !restricted_levels.include?(level)
    end
  end

  def find_file_path
    return unless @project && !@project.empty_repo?

    ref = @ref || @project.repository.root_ref

    project_find_file_path(@project, ref)
  end

  def can_show_last_commit_in_list?(project)
    can?(current_user, :read_cross_project) && project.commit
  end

  def pages_https_only_disabled?
    !@project.pages_domains.all?(&:https?)
  end

  def pages_https_only_title
    return unless pages_https_only_disabled?

    "You must enable HTTPS for all your domains first"
  end

  def pages_https_only_label_class
    if pages_https_only_disabled?
      "list-label disabled"
    else
      "list-label"
    end
  end

  def filter_starrer_path(options = {})
    options = params.slice(:sort).merge(options).permit!
    "#{request.path}?#{options.to_param}"
  end

  def sidebar_projects_paths
    %w[
      projects#show
      projects#activity
      releases#index
      cycle_analytics#show
    ]
  end

  def sidebar_settings_paths
    %w[
      projects#edit
      project_members#index
      integrations#show
      services#edit
      repository#show
      ci_cd#show
      operations#show
      badges#index
      pages#show
    ]
  end

  def sidebar_repository_paths
    %w[
      tree
      blob
      blame
      edit_tree
      new_tree
      find_file
      commit
      commits
      compare
      projects/repositories
      tags
      branches
      graphs
      network
    ]
  end

  def sidebar_operations_paths
    %w[
      environments
      clusters
      functions
      error_tracking
      user
      gcp
      logs
    ]
  end

  def user_can_see_auto_devops_implicitly_enabled_banner?(project, user)
    Ability.allowed?(user, :admin_project, project) &&
      project.has_auto_devops_implicitly_enabled? &&
      project.builds_enabled? &&
      !project.repository.gitlab_ci_yml
  end

  def vue_file_list_enabled?
    Feature.enabled?(:vue_file_list, @project)
  end

  def show_visibility_confirm_modal?(project)
    project.unlink_forks_upon_visibility_decrease_enabled? && project.visibility_level > Gitlab::VisibilityLevel::PRIVATE && project.forks_count > 0
  end
end
