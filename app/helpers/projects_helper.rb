module ProjectsHelper
  prepend ::EE::ProjectsHelper

  def link_to_project(project)
    link_to [project.namespace.becomes(Namespace), project], title: h(project.name) do
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

    content_tag(:span, sanitize(username), name_tag_options)
  end

  def link_to_member(project, author, opts = {}, &block)
    default_opts = { avatar: true, name: true, title: ":name" }
    opts = default_opts.merge(opts)

    return "(deleted)" unless author

    author_html = ""

    # Build avatar image tag
    author_html << link_to_member_avatar(author, opts) if opts[:avatar]

    # Build name span tag
    author_html << author_content_tag(author, opts) if opts[:name]

    author_html << capture(&block) if block

    author_html = author_html.html_safe

    if opts[:name]
      link_to(author_html, user_path(author), class: "author_link #{"#{opts[:extra_class]}" if opts[:extra_class]} #{"#{opts[:mobile_classes]}" if opts[:mobile_classes]}").html_safe
    else
      title = opts[:title].sub(":name", sanitize(author.name))
      link_to(author_html, user_path(author), class: "author_link has-tooltip", title: title, data: { container: 'body' }).html_safe
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
      output =
        if project.avatar_url && !Rails.env.test?
          project_icon(project, alt: project.name, class: 'avatar-tile', width: 15, height: 15)
        else
          ""
        end

      output << content_tag("span", simple_sanitize(project.name), class: "breadcrumb-item-text js-breadcrumb-item-text")
      output.html_safe
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

  def remove_fork_project_message(project)
    _("You are going to remove the fork relationship to source project %{forked_from_project}. Are you ABSOLUTELY sure?") %
      { forked_from_project: fork_source_name(project) }
  end

  def fork_source_name(project)
    if @project.fork_source
      @project.fork_source.full_name
    else
      @project.fork_network&.deleted_root_project_name
    end
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

  def last_push_event
    current_user&.recent_push(@project)
  end

  def project_feature_access_select(field)
    # Don't show option "everyone with access" if project is private
    options = project_feature_options

    level = @project.project_feature.public_send(field) # rubocop:disable GitlabSecurity/PublicSend

    if @project.private?
      disabled_option = ProjectFeature::ENABLED
      highest_available_option = ProjectFeature::PRIVATE if level == disabled_option
    end

    options = options_for_select(
      options.invert,
      selected: highest_available_option || level,
      disabled: disabled_option
    )

    content_tag :div, class: "select-wrapper" do
      concat(
        content_tag(
          :select,
          options,
          name: "project[project_feature_attributes][#{field}]",
          id: "project_project_feature_attributes_#{field}",
          class: "pull-right form-control select-control #{repo_children_classes(field)} ",
          data: { field: field }
        )
      )
      concat(
        icon('chevron-down')
      )
    end.html_safe
  end

  def link_to_autodeploy_doc
    link_to _('About auto deploy'), help_page_path('ci/autodeploy/index'), target: '_blank'
  end

  def autodeploy_flash_notice(branch_name)
    translation = _("Branch <strong>%{branch_name}</strong> was created. To set up auto deploy, choose a GitLab CI Yaml template and commit your changes. %{link_to_autodeploy_doc}") %
      { branch_name: truncate(sanitize(branch_name)), link_to_autodeploy_doc: link_to_autodeploy_doc }
    translation.html_safe
  end

  def project_list_cache_key(project)
    key = [
      project.route.cache_key,
      project.cache_key,
      controller.controller_name,
      controller.action_name,
      Gitlab::CurrentSettings.cache_key,
      "cross-project:#{can?(current_user, :read_cross_project)}",
      'v2.5'
    ]

    key << pipeline_status_cache_key(project.pipeline_status) if project.pipeline_status.has_status?

    key
  end

  def load_pipeline_status(projects)
    Gitlab::Cache::Ci::ProjectPipelineStatus
      .load_in_batch_for_projects(projects)
  end

  def show_no_ssh_key_message?
    cookies[:hide_no_ssh_message].blank? && !current_user.hide_no_ssh_key && current_user.require_ssh_key?
  end

  def show_no_password_message?
    cookies[:hide_no_password_message].blank? && !current_user.hide_no_password &&
      current_user.require_extra_setup_for_git_auth?
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

  def show_projects?(projects, params)
    !!(params[:personal] || params[:name] || any_projects?(projects))
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

  private

  def repo_children_classes(field)
    needs_repo_check = [:merge_requests_access_level, :builds_access_level]
    return unless needs_repo_check.include?(field)

    classes = "project-repo-select js-repo-select"
    classes << " disabled" unless @project.feature_available?(:repository, current_user)

    classes
  end

  def get_project_nav_tabs(project, current_user)
    nav_tabs = [:home]

    if !project.empty_repo? && can?(current_user, :download_code, project)
      nav_tabs << [:files, :commits, :network, :graphs, :forks]
    end

    if project.repo_exists? && can?(current_user, :read_merge_request, project)
      nav_tabs << :merge_requests
    end

    if Gitlab.config.registry.enabled && can?(current_user, :read_container_image, project)
      nav_tabs << :container_registry
    end

    if project.builds_enabled? && can?(current_user, :read_pipeline, project)
      nav_tabs << :pipelines
    end

    if project.external_issue_tracker
      nav_tabs << :external_issue_tracker
    end

    tab_ability_map.each do |tab, ability|
      if can?(current_user, ability, project)
        nav_tabs << tab
      end
    end

    nav_tabs.flatten
  end

  def tab_ability_map
    {
      environments:     :read_environment,
      milestones:       :read_milestone,
      snippets:         :read_project_snippet,
      settings:         :admin_project,
      builds:           :read_build,
      clusters:         :read_cluster,
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
      notes:          [:read_merge_request, :download_code, :read_issue, :read_project_snippet]
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

  def size_limit_message(project)
    show_lfs = project.lfs_enabled? ? 'including files in LFS' : ''

    "The total size of this project's repository #{show_lfs} will be limited to this size. 0 for unlimited. Leave empty to inherit the group/global value."
  end

  def project_above_size_limit_message
    Gitlab::RepositorySizeError.new(@project).above_size_limit_message
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
      current_user.email
    else
      "your@email.com"
    end
  end

  def default_url_to_repo(project = @project)
    case default_clone_protocol
    when 'krb5'
      project.kerberos_url_to_repo
    when 'ssh'
      project.ssh_url_to_repo
    else
      project.http_url_to_repo
    end
  end

  def default_clone_protocol
    if allowed_protocols_present?
      enabled_protocol
    elsif alternative_kerberos_url? && current_user
      "krb5"
    else
      if !current_user || current_user.require_ssh_key?
        gitlab_config.protocol
      else
        'ssh'
      end
    end
  end

  # Given the current GitLab configuration, check whether the GitLab URL for Kerberos is going to be different than the HTTP URL
  def alternative_kerberos_url?
    Gitlab.config.alternative_gitlab_kerberos_url?
  end

  def project_last_activity(project)
    if project.last_activity_at
      time_ago_with_tooltip(project.last_activity_at, placement: 'bottom', html_class: 'last_activity_time_ago')
    else
      s_("ProjectLastActivity|Never")
    end
  end

  def koding_project_url(project = nil, branch = nil, sha = nil)
    if project
      import_path = "/Home/Stacks/import"

      repo = project.full_path
      branch ||= project.default_branch
      sha ||= project.commit.short_id

      path = "#{import_path}?repo=#{repo}&branch=#{branch}&sha=#{sha}"

      return URI.join(Gitlab::CurrentSettings.koding_url, path).to_s
    end

    Gitlab::CurrentSettings.koding_url
  end

  def project_wiki_path_with_version(proj, page, version, is_newest)
    url_params = is_newest ? {} : { version_id: version }
    project_wiki_path(proj, page, url_params)
  end

  def project_status_css_class(status)
    case status
    when "started"
      "active"
    when "failed"
      "danger"
    when "finished"
      "success"
    end
  end

  def project_can_be_shared?
    !membership_locked? || @project.allowed_to_share_with_group?
  end

  def membership_locked?
    if @project.group && @project.group.membership_lock
      true
    else
      false
    end
  end

  def share_project_description
    share_with_group   = @project.allowed_to_share_with_group?
    share_with_members = !membership_locked?
    project_name       = content_tag(:strong, @project.name)
    member_message     = "You can add a new member to #{project_name}"

    description =
      if share_with_group && share_with_members
        "#{member_message} or share it with another group."
      elsif share_with_group
        "You can share #{project_name} with another group."
      elsif share_with_members
        "#{member_message}."
      end

    description.to_s.html_safe
  end

  def readme_cache_key
    sha = @project.commit.try(:sha) || 'nil'
    [@project.full_path, sha, "readme"].join('-')
  end

  def current_ref
    @ref || @repository.try(:root_ref)
  end

  def sanitize_repo_path(project, message)
    return '' unless message.present?

    exports_path = File.join(Settings.shared['path'], 'tmp/project_exports')
    filtered_message = message.strip.gsub(exports_path, "[REPO EXPORT PATH]")

    filtered_message.gsub(project.repository_storage_path.chomp('/'), "[REPOS PATH]")
  end

  def project_feature_options
    {
      ProjectFeature::DISABLED => s_('ProjectFeature|Disabled'),
      ProjectFeature::PRIVATE => s_('ProjectFeature|Only team members'),
      ProjectFeature::ENABLED => s_('ProjectFeature|Everyone with access')
    }
  end

  def project_child_container_class(view_path)
    view_path == "projects/issues/issues" ? "prepend-top-default" : "project-show-#{view_path}"
  end

  def project_issues(project)
    IssuesFinder.new(current_user, project_id: project.id).execute
  end

  def visibility_select_options(project, selected_level)
    level_options = Gitlab::VisibilityLevel.values.each_with_object([]) do |level, level_options|
      next if restricted_levels.include?(level)

      level_options << [
        visibility_level_label(level),
        { data: { description: visibility_level_description(level, project) } },
        level
      ]
    end

    options_for_select(level_options, selected_level)
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
      containerRegistryEnabled: !!project.container_registry_enabled,
      lfsEnabled: !!project.lfs_enabled
    }
  end

  def project_permissions_panel_data(project)
    data = {
      currentSettings: project_permissions_settings(project),
      canChangeVisibilityLevel: can_change_visibility_level?(project, current_user),
      allowedVisibilityOptions: project_allowed_visibility_levels(project),
      visibilityHelpPath: help_page_path('public_access/public_access'),
      registryAvailable: Gitlab.config.registry.enabled,
      registryHelpPath: help_page_path('user/project/container_registry'),
      lfsAvailable: Gitlab.config.lfs.enabled && current_user.admin?,
      lfsHelpPath: help_page_path('workflow/lfs/manage_large_binaries_with_git_lfs')
    }

    data.to_json.html_safe
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
end
