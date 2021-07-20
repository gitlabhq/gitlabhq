# frozen_string_literal: true

module ProjectsHelper
  def project_incident_management_setting
    @project_incident_management_setting ||= @project.incident_management_setting ||
      @project.build_incident_management_setting
  end

  def link_to_project(project)
    link_to namespace_project_path(namespace_id: project.namespace, id: project), title: h(project.name), class: 'gl-link' do
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
    namespace_link = build_namespace_breadcrumb_link(project)
    project_link = build_project_breadcrumb_link(project)

    namespace_link = breadcrumb_list_item(namespace_link) unless project.group
    project_link = breadcrumb_list_item project_link

    "#{namespace_link} #{project_link}".html_safe
  end

  def remove_project_message(project)
    _("You are going to delete %{project_full_name}. Deleted projects CANNOT be restored! Are you ABSOLUTELY sure?") %
      { project_full_name: project.full_name }
  end

  def transfer_project_message(project)
    _("You are going to transfer %{project_full_name} to another namespace. Are you ABSOLUTELY sure?") %
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

  def project_search_tabs?(tab)
    abilities = Array(search_tab_ability_map[tab])

    abilities.any? { |ability| can?(current_user, ability, @project) }
  end

  def can_change_visibility_level?(project, current_user)
    can?(current_user, :change_visibility_level, project)
  end

  def can_disable_emails?(project, current_user)
    return false if project.group&.emails_disabled?

    can?(current_user, :set_emails_disabled, project)
  end

  def last_push_event
    current_user&.recent_push(@project)
  end

  def link_to_autodeploy_doc
    link_to _('About auto deploy'), help_page_path('topics/autodevops/stages.md', anchor: 'auto-deploy'), target: '_blank'
  end

  def autodeploy_flash_notice(branch_name)
    html_escape(_("Branch %{branch_name} was created. To set up auto deploy, choose a GitLab CI Yaml template and commit your changes. %{link_to_autodeploy_doc}")) %
      { branch_name: tag.strong(truncate(sanitize(branch_name))), link_to_autodeploy_doc: link_to_autodeploy_doc }
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

  def explore_projects_tab?
    current_page?(explore_projects_path) ||
      current_page?(trending_explore_projects_path) ||
      current_page?(starred_explore_projects_path)
  end

  def show_merge_request_count?(disabled: false, compact_mode: false)
    !disabled && !compact_mode
  end

  def show_issue_count?(disabled: false, compact_mode: false)
    !disabled && !compact_mode
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
        _("You can invite a new member to %{project_name} or invite another group.")
      elsif share_with_group
        _("You can invite another group to %{project_name}.")
      elsif share_with_members
        _("You can invite a new member to %{project_name}.")
      end

    html_escape(description) % { project_name: tag.strong(project.name) }
  end

  def metrics_external_dashboard_url
    @project.metrics_setting_external_dashboard_url
  end

  def metrics_dashboard_timezone
    @project.metrics_setting_dashboard_timezone
  end

  def grafana_integration_url
    @project.grafana_integration&.grafana_url
  end

  def grafana_integration_masked_token
    @project.grafana_integration&.masked_token
  end

  def grafana_integration_enabled?
    @project.grafana_integration&.enabled?
  end

  def project_license_name(project)
    key = "project:#{project.id}:license_name"

    Gitlab::SafeRequestStore.fetch(key) { project.repository.license&.name }
  rescue GRPC::Unavailable, GRPC::DeadlineExceeded, Gitlab::Git::CommandError => e
    Gitlab::ErrorTracking.track_exception(e)
    Gitlab::SafeRequestStore[key] = nil

    nil
  end

  def show_terraform_banner?(project)
    project.repository_languages.with_programming_language('HCL').exists? && project.terraform_states.empty?
  end

  private

  def tab_ability_map
    {
      cycle_analytics:    :read_cycle_analytics,
      environments:       :read_environment,
      metrics_dashboards: :metrics_dashboard,
      milestones:         :read_milestone,
      snippets:           :read_snippet,
      settings:           :admin_project,
      builds:             :read_build,
      clusters:           :read_cluster,
      serverless:         :read_cluster,
      terraform:          :read_terraform_state,
      error_tracking:     :read_sentry_issue,
      alert_management:   :read_alert_management_alert,
      incidents:          :read_issue,
      labels:             :read_label,
      issues:             :read_issue,
      project_members:    :read_project_member,
      wiki:               :read_wiki,
      feature_flags:      :read_feature_flag,
      analytics:          :read_analytics
    }
  end

  def search_tab_ability_map
    @search_tab_ability_map ||= tab_ability_map.merge(
      blobs:          :download_code,
      commits:        :download_code,
      merge_requests: :read_merge_request,
      notes:          [:read_merge_request, :download_code, :read_issue, :read_snippet],
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

  def project_last_activity(project)
    if project.last_activity_at
      time_ago_with_tooltip(project.last_activity_at, placement: 'bottom', html_class: 'last_activity_time_ago')
    else
      s_("ProjectLastActivity|Never")
    end
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
    view_path == "projects/issues/issues" ? "gl-mt-3" : "project-show-#{view_path}"
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
      packagesEnabled: !!project.packages_enabled,
      visibilityLevel: project.visibility_level,
      requestAccessEnabled: !!project.request_access_enabled,
      issuesAccessLevel: feature.issues_access_level,
      repositoryAccessLevel: feature.repository_access_level,
      forkingAccessLevel: feature.forking_access_level,
      mergeRequestsAccessLevel: feature.merge_requests_access_level,
      buildsAccessLevel: feature.builds_access_level,
      wikiAccessLevel: feature.wiki_access_level,
      snippetsAccessLevel: feature.snippets_access_level,
      pagesAccessLevel: feature.pages_access_level,
      analyticsAccessLevel: feature.analytics_access_level,
      containerRegistryEnabled: !!project.container_registry_enabled,
      lfsEnabled: !!project.lfs_enabled,
      emailsDisabled: project.emails_disabled?,
      metricsDashboardAccessLevel: feature.metrics_dashboard_access_level,
      operationsAccessLevel: feature.operations_access_level,
      showDefaultAwardEmojis: project.show_default_award_emojis?,
      allowEditingCommitMessages: project.allow_editing_commit_messages?,
      securityAndComplianceAccessLevel: project.security_and_compliance_access_level
    }
  end

  def project_permissions_panel_data(project)
    {
      packagesAvailable: ::Gitlab.config.packages.enabled,
      packagesHelpPath: help_page_path('user/packages/index'),
      currentSettings: project_permissions_settings(project),
      canDisableEmails: can_disable_emails?(project, current_user),
      canChangeVisibilityLevel: can_change_visibility_level?(project, current_user),
      allowedVisibilityOptions: project_allowed_visibility_levels(project),
      visibilityHelpPath: help_page_path('public_access/public_access'),
      registryAvailable: Gitlab.config.registry.enabled,
      registryHelpPath: help_page_path('user/packages/container_registry/index'),
      lfsAvailable: Gitlab.config.lfs.enabled,
      lfsHelpPath: help_page_path('topics/git/lfs/index'),
      lfsObjectsExist: project.lfs_objects.exists?,
      lfsObjectsRemovalHelpPath: help_page_path('topics/git/lfs/index', anchor: 'removing-objects-from-lfs'),
      pagesAvailable: Gitlab.config.pages.enabled,
      pagesAccessControlEnabled: Gitlab.config.pages.access_control,
      pagesAccessControlForced: ::Gitlab::Pages.access_control_is_forced?,
      pagesHelpPath: help_page_path('user/project/pages/introduction', anchor: 'gitlab-pages-access-control'),
      issuesHelpPath: help_page_path('user/project/issues/index')
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
    return unless can?(current_user, :download_code, @project)

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

  def sidebar_operations_paths
    %w[
      environments
      clusters
      functions
      error_tracking
      alert_management
      incidents
      incident_management
      user
      gcp
      logs
      product_analytics
      metrics_dashboard
      feature_flags
      tracings
      terraform
    ]
  end

  def user_can_see_auto_devops_implicitly_enabled_banner?(project, user)
    Ability.allowed?(user, :admin_project, project) &&
      project.has_auto_devops_implicitly_enabled? &&
      project.builds_enabled? &&
      !project.repository.gitlab_ci_yml
  end

  def show_visibility_confirm_modal?(project)
    project.unlink_forks_upon_visibility_decrease_enabled? && project.visibility_level > Gitlab::VisibilityLevel::PRIVATE && project.forks_count > 0
  end

  def build_project_breadcrumb_link(project)
    project_name = simple_sanitize(project.name)

    push_to_schema_breadcrumb(project_name, project_path(project))

    link_to project_path(project) do
      icon = project_icon(project, alt: project_name, class: 'avatar-tile', width: 15, height: 15) if project.avatar_url && !Rails.env.test?
      [icon, content_tag("span", project_name, class: "breadcrumb-item-text js-breadcrumb-item-text")].join.html_safe
    end
  end

  def build_namespace_breadcrumb_link(project)
    if project.group
      group_title(project.group, nil, nil)
    else
      owner = project.namespace.owner
      name = simple_sanitize(owner.name)
      url = user_path(owner)

      push_to_schema_breadcrumb(name, url)
      link_to(name, url)
    end
  end
end

ProjectsHelper.prepend_mod_with('ProjectsHelper')
