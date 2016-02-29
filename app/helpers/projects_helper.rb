module ProjectsHelper
  def remove_from_project_team_message(project, member)
    if member.user
      "You are going to remove #{member.user.name} from #{project.name} project team. Are you sure?"
    else
      "You are going to revoke the invitation for #{member.invite_email} to join #{project.name} project team. Are you sure?"
    end
  end

  def link_to_project(project)
    link_to [project.namespace.becomes(Namespace), project] do
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
    image_tag(avatar_icon(author, opts[:size]), width: opts[:size], class: "avatar avatar-inline #{"s#{opts[:size]}" if opts[:size]}", alt:'') if opts[:avatar]
  end

  def link_to_member(project, author, opts = {})
    default_opts = { avatar: true, name: true, size: 16, author_class: 'author', title: ":name" }
    opts = default_opts.merge(opts)

    return "(deleted)" unless author

    author_html =  ""

    # Build avatar image tag
    author_html << image_tag(avatar_icon(author, opts[:size]), width: opts[:size], class: "avatar avatar-inline #{"s#{opts[:size]}" if opts[:size]}", alt:'') if opts[:avatar]

    # Build name span tag
    if opts[:by_username]
      author_html << content_tag(:span, sanitize("@#{author.username}"), class: opts[:author_class]) if opts[:name]
    else
      author_html << content_tag(:span, sanitize(author.name), class: opts[:author_class]) if opts[:name]
    end

    author_html = author_html.html_safe

    if opts[:name]
      link_to(author_html, user_path(author), class: "author_link #{"#{opts[:mobile_classes]}" if opts[:mobile_classes]}").html_safe
    else
      title = opts[:title].sub(":name", sanitize(author.name))
      link_to(author_html, user_path(author), class: "author_link has_tooltip", data: { 'original-title'.to_sym => title, container: 'body' } ).html_safe
    end
  end

  def project_title(project, name = nil, url = nil)
    namespace_link =
      if project.group
        link_to(simple_sanitize(project.group.name), group_path(project.group))
      else
        owner = project.namespace.owner
        link_to(simple_sanitize(owner.name), user_path(owner))
      end

    project_link = link_to project_path(project), { class: "project-item-select-holder" } do
      link_output = simple_sanitize(project.name)

      if current_user
        link_output += project_select_tag :project_path,
          class: "project-item-select js-projects-dropdown",
          data: { include_groups: false, order_by: 'last_activity_at' }
      end

      link_output
    end
    project_link += icon "chevron-down", class: "dropdown-toggle-caret js-projects-dropdown-toggle" if current_user

    full_title = namespace_link + ' / ' + project_link
    full_title += ' &middot; '.html_safe + link_to(simple_sanitize(name), url) if name

    full_title
  end

  def remove_project_message(project)
    "You are going to remove #{project.name_with_namespace}.\n Removed project CANNOT be restored!\n Are you ABSOLUTELY sure?"
  end

  def transfer_project_message(project)
    "You are going to transfer #{project.name_with_namespace} to another owner. Are you ABSOLUTELY sure?"
  end

  def remove_fork_project_message(project)
    "You are going to remove the fork relationship to source project #{@project.forked_from_project.name_with_namespace}.  Are you ABSOLUTELY sure?"
  end

  def project_nav_tabs
    @nav_tabs ||= get_project_nav_tabs(@project, current_user)
  end

  def project_nav_tab?(name)
    project_nav_tabs.include? name
  end

  def project_for_deploy_key(deploy_key)
    if deploy_key.projects.include?(@project)
      @project
    else
      deploy_key.projects.find { |project| can?(current_user, :read_project, project) }
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

  def user_max_access_in_project(user_id, project)
    level = project.team.max_member_access(user_id)

    if level
      Gitlab::Access.options_with_owner.key(level)
    end
  end

  private

  def get_project_nav_tabs(project, current_user)
    nav_tabs = [:home, :forks]

    if !project.empty_repo? && can?(current_user, :download_code, project)
      nav_tabs << [:files, :commits, :network, :graphs]
    end

    if project.repo_exists? && can?(current_user, :read_merge_request, project)
      nav_tabs << :merge_requests
    end

    if can?(current_user, :read_build, project)
      nav_tabs << :builds
    end

    if can?(current_user, :admin_project, project)
      nav_tabs << :settings
    end

    if can?(current_user, :read_issue, project)
      nav_tabs << :issues
    end

    if can?(current_user, :read_wiki, project)
      nav_tabs << :wiki
    end

    if can?(current_user, :read_project_snippet, project)
      nav_tabs << :snippets
    end

    if can?(current_user, :read_label, project)
      nav_tabs << :labels
    end

    if can?(current_user, :read_milestone, project)
      nav_tabs << :milestones
    end

    nav_tabs.flatten
  end

  def git_user_name
    if current_user
      current_user.name
    else
      "Your name"
    end
  end

  def git_user_email
    if current_user
      current_user.email
    else
      "your@email.com"
    end
  end

  def repository_size(project = @project)
    "#{project.repository_size} MB"
  rescue
    # In order to prevent 500 error
    # when application cannot allocate memory
    # to calculate repo size - just show 'Unknown'
    'unknown'
  end

  def default_url_to_repo(project = @project)
    if default_clone_protocol == "ssh"
      project.ssh_url_to_repo
    else
      project.http_url_to_repo
    end
  end

  def default_clone_protocol
    if !current_user || current_user.require_ssh_key?
      "http"
    else
      "ssh"
    end
  end

  def project_last_activity(project)
    if project.last_activity_at
      time_ago_with_tooltip(project.last_activity_at, placement: 'bottom', html_class: 'last_activity_time_ago')
    else
      "Never"
    end
  end

  def add_contribution_guide_path(project)
    if project && !project.repository.contribution_guide
      namespace_project_new_blob_path(
        project.namespace,
        project,
        project.default_branch,
        file_name:      "CONTRIBUTING.md",
        commit_message: "Add contribution guide"
      )
    end
  end

  def add_changelog_path(project)
    if project && !project.repository.changelog
      namespace_project_new_blob_path(
        project.namespace,
        project,
        project.default_branch,
        file_name:      "CHANGELOG",
        commit_message: "Add changelog"
      )
    end
  end

  def add_license_path(project)
    if project && !project.repository.license
      namespace_project_new_blob_path(
        project.namespace,
        project,
        project.default_branch,
        file_name:      "LICENSE",
        commit_message: "Add license"
      )
    end
  end

  def contribution_guide_path(project)
    if project && contribution_guide = project.repository.contribution_guide
      namespace_project_blob_path(
        project.namespace,
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
    filename_path(project, :license)
  end

  def version_path(project)
    filename_path(project, :version)
  end

  def project_wiki_path_with_version(proj, page, version, is_newest)
    url_params = is_newest ? {} : { version_id: version }
    namespace_project_wiki_path(proj.namespace, proj, page, url_params)
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

  def leave_project_message(project)
    "Are you sure you want to leave \"#{project.name}\" project?"
  end

  def new_readme_path
    ref = @repository.root_ref if @repository
    ref ||= 'master'

    namespace_project_new_blob_path(@project.namespace, @project, tree_join(ref), file_name: 'README.md')
  end

  def last_push_event
    if current_user
      current_user.recent_push(@project.id)
    end
  end

  def readme_cache_key
    sha = @project.commit.try(:sha) || 'nil'
    [@project.path_with_namespace, sha, "readme"].join('-')
  end

  def round_commit_count(project)
    count = project.commit_count

    if count > 10000
      '10000+'
    elsif count > 5000
      '5000+'
    elsif count > 1000
      '1000+'
    else
      count
    end
  end

  def current_ref
    @ref || @repository.try(:root_ref)
  end

  private

  def filename_path(project, filename)
    if project && blob = project.repository.send(filename)
      namespace_project_blob_path(
        project.namespace,
        project,
        tree_join(project.default_branch, blob.name)
      )
    end
  end
end
