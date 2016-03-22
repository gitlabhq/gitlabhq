module SearchHelper

  CAT_SETTINGS = 'Settings'
  CAT_HELP = 'Help'
  CAT_CURR_PROJECT = 'Current Project'
  CAT_GROUPS = 'Groups'
  CAT_PROJECTS = 'Projects'

  def search_autocomplete_opts(term)
    return unless current_user

    resources_results = [
      groups_autocomplete(term),
      projects_autocomplete(term)
    ].flatten

    generic_results = project_autocomplete + default_autocomplete + help_autocomplete
    generic_results.select! { |result| result[:label] =~ Regexp.new(term, "i") }

    [
      resources_results,
      generic_results
    ].flatten.uniq do |item|
      item[:label]
    end
  end

  private

  # Autocomplete results for various settings pages
  def default_autocomplete
    [
      { category: CAT_SETTINGS, label: "Profile settings", url: profile_path },
      { category: CAT_SETTINGS, label: "SSH Keys",         url: profile_keys_path },
      { category: CAT_SETTINGS, label: "Dashboard",        url: root_path },
      { category: CAT_SETTINGS, label: "Admin Section",    url: admin_root_path },
    ]
  end

  # Autocomplete results for internal help pages
  def help_autocomplete
    [
      { category: CAT_HELP, label: "API Help",           url: help_page_path("api", "README") },
      { category: CAT_HELP, label: "Markdown Help",      url: help_page_path("markdown", "markdown") },
      { category: CAT_HELP, label: "Permissions Help",   url: help_page_path("permissions", "permissions") },
      { category: CAT_HELP, label: "Public Access Help", url: help_page_path("public_access", "public_access") },
      { category: CAT_HELP, label: "Rake Tasks Help",    url: help_page_path("raketasks", "README") },
      { category: CAT_HELP, label: "SSH Keys Help",      url: help_page_path("ssh", "README") },
      { category: CAT_HELP, label: "System Hooks Help",  url: help_page_path("system_hooks", "system_hooks") },
      { category: CAT_HELP, label: "Webhooks Help",      url: help_page_path("web_hooks", "web_hooks") },
      { category: CAT_HELP, label: "Workflow Help",      url: help_page_path("workflow", "README") },
    ]
  end

  # Autocomplete results for the current project, if it's defined
  def project_autocomplete
    if @project && @project.repository.exists? && @project.repository.root_ref
      ref    = @ref || @project.repository.root_ref

      [
        { category: CAT_CURR_PROJECT, label: "Files",          url: namespace_project_tree_path(@project.namespace, @project, ref) },
        { category: CAT_CURR_PROJECT, label: "Commits",        url: namespace_project_commits_path(@project.namespace, @project, ref) },
        { category: CAT_CURR_PROJECT, label: "Network",        url: namespace_project_network_path(@project.namespace, @project, ref) },
        { category: CAT_CURR_PROJECT, label: "Graph",          url: namespace_project_graph_path(@project.namespace, @project, ref) },
        { category: CAT_CURR_PROJECT, label: "Issues",         url: namespace_project_issues_path(@project.namespace, @project) },
        { category: CAT_CURR_PROJECT, label: "Merge Requests", url: namespace_project_merge_requests_path(@project.namespace, @project) },
        { category: CAT_CURR_PROJECT, label: "Milestones",     url: namespace_project_milestones_path(@project.namespace, @project) },
        { category: CAT_CURR_PROJECT, label: "Snippets",       url: namespace_project_snippets_path(@project.namespace, @project) },
        { category: CAT_CURR_PROJECT, label: "Members",        url: namespace_project_project_members_path(@project.namespace, @project) },
        { category: CAT_CURR_PROJECT, label: "Wiki",           url: namespace_project_wikis_path(@project.namespace, @project) },
      ]
    else
      []
    end
  end

  # Autocomplete results for the current user's groups
  def groups_autocomplete(term, limit = 5)
    current_user.authorized_groups.search(term).limit(limit).map do |group|
      {
        category: CAT_GROUPS,
        id: group.id,
        label: "#{search_result_sanitize(group.name)}",
        url: group_path(group)
      }
    end
  end

  # Autocomplete results for the current user's projects
  def projects_autocomplete(term, limit = 5)
    current_user.authorized_projects.search_by_title(term).
      sorted_by_stars.non_archived.limit(limit).map do |p|
      {
        category: CAT_PROJECTS,
        id: p.id,
        value: "#{search_result_sanitize(p.name)}",
        label: "#{search_result_sanitize(p.name_with_namespace)}",
        url: namespace_project_path(p.namespace, p)
      }
    end
  end

  def search_result_sanitize(str)
    Sanitize.clean(str)
  end

  def search_filter_path(options={})
    exist_opts = {
      search: params[:search],
      project_id: params[:project_id],
      group_id: params[:group_id],
      scope: params[:scope]
    }

    options = exist_opts.merge(options)
    search_path(options)
  end

  # Sanitize html generated after parsing markdown from issue description or comment
  def search_md_sanitize(html)
    sanitize(html, tags: %w(a p ol ul li pre code))
  end
end
