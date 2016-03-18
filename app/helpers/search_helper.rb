module SearchHelper
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
      { label: "Profile settings", url: profile_path },
      { label: "SSH Keys",         url: profile_keys_path },
      { label: "Dashboard",        url: root_path },
      { label: "Admin Section",       url: admin_root_path },
    ]
  end

  # Autocomplete results for internal help pages
  def help_autocomplete
    [
      { label: "help: API Help",           url: help_page_path("api", "README") },
      { label: "help: Markdown Help",      url: help_page_path("markdown", "markdown") },
      { label: "help: Permissions Help",   url: help_page_path("permissions", "permissions") },
      { label: "help: Public Access Help", url: help_page_path("public_access", "public_access") },
      { label: "help: Rake Tasks Help",    url: help_page_path("raketasks", "README") },
      { label: "help: SSH Keys Help",      url: help_page_path("ssh", "README") },
      { label: "help: System Hooks Help",  url: help_page_path("system_hooks", "system_hooks") },
      { label: "help: Webhooks Help",      url: help_page_path("web_hooks", "web_hooks") },
      { label: "help: Workflow Help",      url: help_page_path("workflow", "README") },
    ]
  end

  # Autocomplete results for the current project, if it's defined
  def project_autocomplete
    if @project && @project.repository.exists? && @project.repository.root_ref
      prefix = search_result_sanitize(@project.name_with_namespace)
      ref    = @ref || @project.repository.root_ref

      [
        { label: "#{prefix} - Files",          url: namespace_project_tree_path(@project.namespace, @project, ref) },
        { label: "#{prefix} - Commits",        url: namespace_project_commits_path(@project.namespace, @project, ref) },
        { label: "#{prefix} - Network",        url: namespace_project_network_path(@project.namespace, @project, ref) },
        { label: "#{prefix} - Graph",          url: namespace_project_graph_path(@project.namespace, @project, ref) },
        { label: "#{prefix} - Issues",         url: namespace_project_issues_path(@project.namespace, @project) },
        { label: "#{prefix} - Merge Requests", url: namespace_project_merge_requests_path(@project.namespace, @project) },
        { label: "#{prefix} - Milestones",     url: namespace_project_milestones_path(@project.namespace, @project) },
        { label: "#{prefix} - Snippets",       url: namespace_project_snippets_path(@project.namespace, @project) },
        { label: "#{prefix} - Members",        url: namespace_project_project_members_path(@project.namespace, @project) },
        { label: "#{prefix} - Wiki",           url: namespace_project_wikis_path(@project.namespace, @project) },
      ]
    else
      []
    end
  end

  # Autocomplete results for the current user's groups
  def groups_autocomplete(term, limit = 5)
    current_user.authorized_groups.search(term).limit(limit).map do |group|
      {
        label: "group: #{search_result_sanitize(group.name)}",
        url: group_path(group)
      }
    end
  end

  # Autocomplete results for the current user's projects
  def projects_autocomplete(term, limit = 5)
    current_user.authorized_projects.search_by_title(term).
      sorted_by_stars.non_archived.limit(limit).map do |p|
      {
        label: "project: #{search_result_sanitize(p.name_with_namespace)}",
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
