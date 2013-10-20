module SearchHelper
  def search_autocomplete_source
    return unless current_user

    [
      groups_autocomplete,
      projects_autocomplete,
      default_autocomplete,
      project_autocomplete,
      help_autocomplete
    ].flatten.to_json
  end

  private

  # Autocomplete results for various settings pages
  def default_autocomplete
    [
      { label: "My Profile settings", url: profile_path },
      { label: "My SSH Keys",         url: profile_keys_path },
      { label: "My Dashboard",        url: root_path },
      { label: "Admin Section",       url: admin_root_path },
    ]
  end

  # Autocomplete results for internal help pages
  def help_autocomplete
    [
      { label: "help: API Help",           url: help_api_path },
      { label: "help: Markdown Help",      url: help_markdown_path },
      { label: "help: Permissions Help",   url: help_permissions_path },
      { label: "help: Public Access Help", url: help_public_access_path },
      { label: "help: Rake Tasks Help",    url: help_raketasks_path },
      { label: "help: SSH Keys Help",      url: help_ssh_path },
      { label: "help: System Hooks Help",  url: help_system_hooks_path },
      { label: "help: Web Hooks Help",     url: help_web_hooks_path },
      { label: "help: Workflow Help",      url: help_workflow_path },
    ]
  end

  # Autocomplete results for the current project, if it's defined
  def project_autocomplete
    if @project && @project.repository.exists? && @project.repository.root_ref
      prefix = simple_sanitize(@project.name_with_namespace)
      ref    = @ref || @project.repository.root_ref

      [
        { label: "#{prefix} - Files",          url: project_tree_path(@project, ref) },
        { label: "#{prefix} - Commits",        url: project_commits_path(@project, ref) },
        { label: "#{prefix} - Network",        url: project_network_path(@project, ref) },
        { label: "#{prefix} - Graph",          url: project_graph_path(@project, ref) },
        { label: "#{prefix} - Issues",         url: project_issues_path(@project) },
        { label: "#{prefix} - Merge Requests", url: project_merge_requests_path(@project) },
        { label: "#{prefix} - Milestones",     url: project_milestones_path(@project) },
        { label: "#{prefix} - Snippets",       url: project_snippets_path(@project) },
        { label: "#{prefix} - Team",           url: project_team_index_path(@project) },
        { label: "#{prefix} - Wall",           url: project_wall_path(@project) },
        { label: "#{prefix} - Wiki",           url: project_wikis_path(@project) },
      ]
    else
      []
    end
  end

  # Autocomplete results for the current user's groups
  def groups_autocomplete
    current_user.authorized_groups.map do |group|
      { label: "group: #{simple_sanitize(group.name)}", url: group_path(group) }
    end
  end

  # Autocomplete results for the current user's projects
  def projects_autocomplete
    current_user.authorized_projects.map do |p|
      { label: "project: #{simple_sanitize(p.name_with_namespace)}", url: project_path(p) }
    end
  end
end
