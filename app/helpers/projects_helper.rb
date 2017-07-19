module ProjectsHelper
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
    default_opts = { avatar: true, name: true, size: 16, author_class: 'author', title: ":name" }
    opts = default_opts.merge(opts)
    image_tag(avatar_icon(author, opts[:size]), width: opts[:size], class: "avatar avatar-inline #{"s#{opts[:size]}" if opts[:size]}", alt: '') if opts[:avatar]
  end

  def link_to_member(project, author, opts = {}, &block)
    default_opts = { avatar: true, name: true, size: 16, author_class: 'author', title: ":name", tooltip: false }
    opts = default_opts.merge(opts)

    return "(deleted)" unless author

    author_html = ""

    # Build avatar image tag
    author_html << image_tag(avatar_icon(author, opts[:size]), width: opts[:size], class: "avatar avatar-inline #{"s#{opts[:size]}" if opts[:size]} #{opts[:avatar_class] if opts[:avatar_class]}", alt: '') if opts[:avatar]

    # Build name span tag
    if opts[:by_username]
      author_html << content_tag(:span, sanitize("@#{author.username}"), class: opts[:author_class]) if opts[:name]
    else
      tooltip_data = { placement: 'top' }
      author_html << content_tag(:span, sanitize(author.name), class: [opts[:author_class], ('has-tooltip' if opts[:tooltip])], title: (author.to_reference if opts[:tooltip]), data: (tooltip_data if opts[:tooltip])) if opts[:name]
    end

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
        group_title(project.group)
      else
        owner = project.namespace.owner
        link_to(simple_sanitize(owner.name), user_path(owner))
      end

    project_link = link_to project_path(project), { class: "project-item-select-holder" } do
      output =
        if show_new_nav?
          project_icon(project, alt: project.name, class: 'avatar-tile', width: 16, height: 16)
        else
          ""
        end

      output << simple_sanitize(project.name)
      output.html_safe
    end

    if current_user
      project_link << button_tag(type: 'button', class: 'dropdown-toggle-caret js-projects-dropdown-toggle', aria: { label: 'Toggle switch project dropdown' }, data: { target: '.js-dropdown-menu-projects', toggle: 'dropdown', order_by: 'last_activity_at' }) do
        icon("chevron-down")
      end
    end

    "#{namespace_link} / #{project_link}".html_safe
  end

  def remove_project_message(project)
    _("You are going to remove %{project_name_with_namespace}.\nRemoved project CANNOT be restored!\nAre you ABSOLUTELY sure?") %
      { project_name_with_namespace: project.name_with_namespace }
  end

  def transfer_project_message(project)
    _("You are going to transfer %{project_name_with_namespace} to another owner. Are you ABSOLUTELY sure?") %
      { project_name_with_namespace: project.name_with_namespace }
  end

  def remove_fork_project_message(project)
    _("You are going to remove the fork relationship to source project %{forked_from_project}. Are you ABSOLUTELY sure?") %
      { forked_from_project: @project.forked_from_project.name_with_namespace }
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

    if project.forked?
      project.forked_from_project.visibility_level > Gitlab::VisibilityLevel::PRIVATE
    else
      true
    end
  end

  def license_short_name(project)
    license = project.repository.license
    license&.nickname || license&.name || 'LICENSE'
  end

  def last_push_event
    return unless current_user
    return current_user.recent_push unless @project

    project_ids = [@project.id]
    if fork = current_user.fork_of(@project)
      project_ids << fork.id
    end

    current_user.recent_push(project_ids)
  end

  def project_feature_access_select(field)
    # Don't show option "everyone with access" if project is private
    options = project_feature_options

    if @project.private?
      level = @project.project_feature.send(field)
      disabled_option = ProjectFeature::ENABLED
      highest_available_option = ProjectFeature::PRIVATE if level == disabled_option
    end

    options = options_for_select(
      options.invert,
      selected: highest_available_option || @project.project_feature.public_send(field),
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
      current_application_settings.cache_key,
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
      ( current_user.require_password_creation? || current_user.require_personal_access_token_creation_for_git_auth? )
  end

  def link_to_set_password
    if current_user.require_password_creation?
      link_to s_('SetPasswordToCloneLink|set a password'), edit_profile_password_path
    else
      link_to s_('CreateTokenToCloneLink|create a personal access token'), profile_personal_access_tokens_path
    end
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
      current_user.name
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

  def add_special_file_path(project, file_name:, commit_message: nil, branch_name: nil, context: nil)
    commit_message ||= s_("CommitMessage|Add %{file_name}") % { file_name: file_name.downcase }
    project_new_blob_path(
      project,
      project.default_branch || 'master',
      file_name:      file_name,
      commit_message: commit_message,
      branch_name: branch_name,
      context: context
    )
  end

  def add_koding_stack_path(project)
    project_new_blob_path(
      project,
      project.default_branch || 'master',
      file_name:      '.koding.yml',
      commit_message: "Add Koding stack script",
      content: <<-CONTENT.strip_heredoc
        provider:
          aws:
            access_key: '${var.aws_access_key}'
            secret_key: '${var.aws_secret_key}'
        resource:
          aws_instance:
            #{project.path}-vm:
              instance_type: t2.nano
              user_data: |-

                # Created by GitLab UI for :>

                echo _KD_NOTIFY_@Installing Base packages...@

                apt-get update -y
                apt-get install git -y

                echo _KD_NOTIFY_@Cloning #{project.name}...@

                export KODING_USER=${var.koding_user_username}
                export REPO_URL=#{root_url}${var.koding_queryString_repo}.git
                export BRANCH=${var.koding_queryString_branch}

                sudo -i -u $KODING_USER git clone $REPO_URL -b $BRANCH

                echo _KD_NOTIFY_@#{project.name} cloned.@
      CONTENT
    )
  end

  def koding_project_url(project = nil, branch = nil, sha = nil)
    if project
      import_path = "/Home/Stacks/import"

      repo = project.path_with_namespace
      branch ||= project.default_branch
      sha ||= project.commit.short_id

      path = "#{import_path}?repo=#{repo}&branch=#{branch}&sha=#{sha}"

      return URI.join(current_application_settings.koding_url, path).to_s
    end

    current_application_settings.koding_url
  end

  def contribution_guide_path(project)
    if project && contribution_guide = project.repository.contribution_guide
      project_blob_path(
        project,
        tree_join(project.default_branch,
                  contribution_guide.name)
      )
    end
  end

  def readme_path(project)
    filename_path(project, :readme)
  end

  def changelog_path(project)
    filename_path(project, :changelog)
  end

  def license_path(project)
    filename_path(project, :license_blob)
  end

  def version_path(project)
    filename_path(project, :version)
  end

  def ci_configuration_path(project)
    filename_path(project, :gitlab_ci_yml)
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

  def can_force_update_mirror?(project)
    return true unless project.mirror_last_update_at

    Time.now - project.mirror_last_update_at >= 5.minutes
  end

  def membership_locked?
    if @project.group && @project.group.membership_lock
      true
    else
      false
    end
  end

  def readme_cache_key
    sha = @project.commit.try(:sha) || 'nil'
    [@project.path_with_namespace, sha, "readme"].join('-')
  end

  def current_ref
    @ref || @repository.try(:root_ref)
  end

  def filename_path(project, filename)
    if project && blob = project.repository.send(filename)
      project_blob_path(
        project,
        tree_join(project.default_branch, blob.name)
      )
    end
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

    current_application_settings.restricted_visibility_levels || []
  end

  def find_file_path
    return unless @project && !@project.empty_repo?

    ref = @ref || @project.repository.root_ref

    project_find_file_path(@project, ref)
  end
end
