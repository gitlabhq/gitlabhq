module SearchHelper
  def search_autocomplete_opts(term)
    return unless current_user

    resources_results = [
      groups_autocomplete(term),
      projects_autocomplete(term)
    ].flatten

    search_pattern = Regexp.new(Regexp.escape(term), "i")

    generic_results = project_autocomplete + default_autocomplete + help_autocomplete
    generic_results.concat(default_autocomplete_admin) if current_user.admin?
    generic_results.select! { |result| result[:label] =~ search_pattern }

    [
      resources_results,
      generic_results
    ].flatten.uniq do |item|
      item[:label]
    end
  end

  def search_entries_info(collection, scope, term)
    return unless collection.count > 0

    from = collection.offset_value + 1
    to = collection.offset_value + collection.length
    count = collection.total_count

    "Showing #{from} - #{to} of #{count} #{scope.humanize(capitalize: false)} for \"#{term}\""
  end

  def parse_search_result(result)
    Gitlab::ProjectSearchResults.parse_search_result(result)
  end

  private

  # Autocomplete results for various settings pages
  def default_autocomplete
    [
      { category: "Settings", label: "User settings",    url: profile_path },
      { category: "Settings", label: "SSH Keys",         url: profile_keys_path },
      { category: "Settings", label: "Dashboard",        url: root_path }
    ]
  end

  # Autocomplete results for settings pages, for admins
  def default_autocomplete_admin
    [
      { category: "Settings", label: "Admin Section", url: admin_root_path }
    ]
  end

  # Autocomplete results for internal help pages
  def help_autocomplete
    [
      { category: "Help", label: "API Help",           url: help_page_path("api/README") },
      { category: "Help", label: "Markdown Help",      url: help_page_path("user/markdown") },
      { category: "Help", label: "Permissions Help",   url: help_page_path("user/permissions") },
      { category: "Help", label: "Public Access Help", url: help_page_path("public_access/public_access") },
      { category: "Help", label: "Rake Tasks Help",    url: help_page_path("raketasks/README") },
      { category: "Help", label: "SSH Keys Help",      url: help_page_path("ssh/README") },
      { category: "Help", label: "System Hooks Help",  url: help_page_path("system_hooks/system_hooks") },
      { category: "Help", label: "Webhooks Help",      url: help_page_path("user/project/integrations/webhooks") },
      { category: "Help", label: "Workflow Help",      url: help_page_path("workflow/README") }
    ]
  end

  # Autocomplete results for the current project, if it's defined
  def project_autocomplete
    if @project && @project.repository.exists? && @project.repository.root_ref
      ref = @ref || @project.repository.root_ref

      [
        { category: "Current Project", label: "Files",          url: project_tree_path(@project, ref) },
        { category: "Current Project", label: "Commits",        url: project_commits_path(@project, ref) },
        { category: "Current Project", label: "Network",        url: project_network_path(@project, ref) },
        { category: "Current Project", label: "Graph",          url: project_graph_path(@project, ref) },
        { category: "Current Project", label: "Issues",         url: project_issues_path(@project) },
        { category: "Current Project", label: "Merge Requests", url: project_merge_requests_path(@project) },
        { category: "Current Project", label: "Milestones",     url: project_milestones_path(@project) },
        { category: "Current Project", label: "Snippets",       url: project_snippets_path(@project) },
        { category: "Current Project", label: "Members",        url: project_project_members_path(@project) },
        { category: "Current Project", label: "Wiki",           url: project_wikis_path(@project) }
      ]
    else
      []
    end
  end

  # Autocomplete results for the current user's groups
  def groups_autocomplete(term, limit = 5)
    current_user.authorized_groups.order_id_desc.search(term).limit(limit).map do |group|
      {
        category: "Groups",
        id: group.id,
        label: "#{search_result_sanitize(group.full_name)}",
        url: group_path(group)
      }
    end
  end

  # Autocomplete results for the current user's projects
  def projects_autocomplete(term, limit = 5)
    current_user.authorized_projects.order_id_desc.search_by_title(term)
      .sorted_by_stars.non_archived.limit(limit).map do |p|
      {
        category: "Projects",
        id: p.id,
        value: "#{search_result_sanitize(p.name)}",
        label: "#{search_result_sanitize(p.full_name)}",
        url: project_path(p)
      }
    end
  end

  def search_result_sanitize(str)
    Sanitize.clean(str)
  end

  def search_filter_path(options = {})
    exist_opts = {
      search: params[:search],
      project_id: params[:project_id],
      group_id: params[:group_id],
      scope: params[:scope],
      repository_ref: params[:repository_ref]
    }

    options = exist_opts.merge(options)
    search_path(options)
  end

  def search_filter_input_options(type)
    opts =
      {
        id: "filtered-search-#{type}",
        placeholder: 'Search or filter results...',
        data: {
          'username-params' => UserSerializer.new.represent(@users)
        },
        autocomplete: 'off'
      }

    if @project.present?
      opts[:data]['project-id'] = @project.id
      opts[:data]['base-endpoint'] = project_path(@project)
    else
      # Group context
      opts[:data]['group-id'] = @group.id
      opts[:data]['base-endpoint'] = group_canonical_path(@group)
    end

    opts
  end

  # Sanitize a HTML field for search display. Most tags are stripped out and the
  # maximum length is set to 200 characters.
  def search_md_sanitize(object, field)
    html = markdown_field(object, field)
    html = Truncato.truncate(
      html,
      count_tags: false,
      count_tail: false,
      max_length: 200
    )

    # Truncato's filtered_tags and filtered_attributes are not quite the same
    sanitize(html, tags: %w(a p ol ul li pre code))
  end

  def limited_count(count, limit = 1000)
    count > limit ? "#{limit}+" : count
  end
end
