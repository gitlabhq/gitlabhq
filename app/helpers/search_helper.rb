# frozen_string_literal: true

module SearchHelper
  SEARCH_PERMITTED_PARAMS = [:search, :scope, :project_id, :group_id, :repository_ref, :snippets].freeze

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
    return if collection.to_a.empty?

    from = collection.offset_value + 1
    to = collection.offset_value + collection.to_a.size
    count = collection.total_count
    term_element = "<span>&nbsp;<code>#{h(term)}</code>&nbsp;</span>".html_safe

    search_entries_info_template(collection) % {
      from: from,
      to: to,
      count: count,
      scope: search_entries_scope_label(scope, count),
      term_element: term_element
    }
  end

  def search_entries_scope_label(scope, count)
    case scope
    when 'blobs'
      ns_('SearchResults|code result', 'SearchResults|code results', count)
    when 'commits'
      ns_('SearchResults|commit', 'SearchResults|commits', count)
    when 'issues'
      ns_('SearchResults|issue', 'SearchResults|issues', count)
    when 'merge_requests'
      ns_('SearchResults|merge request', 'SearchResults|merge requests', count)
    when 'milestones'
      ns_('SearchResults|milestone', 'SearchResults|milestones', count)
    when 'notes'
      ns_('SearchResults|comment', 'SearchResults|comments', count)
    when 'projects'
      ns_('SearchResults|project', 'SearchResults|projects', count)
    when 'snippet_blobs'
      ns_('SearchResults|snippet result', 'SearchResults|snippet results', count)
    when 'snippet_titles'
      ns_('SearchResults|snippet', 'SearchResults|snippets', count)
    when 'users'
      ns_('SearchResults|user', 'SearchResults|users', count)
    when 'wiki_blobs'
      ns_('SearchResults|wiki result', 'SearchResults|wiki results', count)
    else
      raise "Unrecognized search scope '#{scope}'"
    end
  end

  def search_entries_info_template(collection)
    if collection.total_pages > 1
      s_("SearchResults|Showing %{from} - %{to} of %{count} %{scope} for%{term_element}").html_safe
    else
      s_("SearchResults|Showing %{count} %{scope} for%{term_element}").html_safe
    end
  end

  def search_entries_empty_message(scope, term)
    (s_("SearchResults|We couldn't find any %{scope} matching %{term}") % {
      scope: search_entries_scope_label(scope, 0),
      term: "<code>#{h(term)}</code>"
    }).html_safe
  end

  def find_project_for_result_blob(projects, result)
    @project
  end

  # Used in EE
  def blob_projects(results)
    nil
  end

  def parse_search_result(result)
    result
  end

  # Overriden in EE
  def search_blob_title(project, path)
    path
  end

  def search_service
    @search_service ||= ::SearchService.new(current_user, params)
  end

  private

  # Autocomplete results for various settings pages
  def default_autocomplete
    [
      { category: "Settings", label: _("User settings"),    url: profile_path },
      { category: "Settings", label: _("SSH Keys"),         url: profile_keys_path },
      { category: "Settings", label: _("Dashboard"),        url: root_path }
    ]
  end

  # Autocomplete results for settings pages, for admins
  def default_autocomplete_admin
    [
      { category: "Settings", label: _("Admin Section"), url: admin_root_path }
    ]
  end

  # Autocomplete results for internal help pages
  def help_autocomplete
    [
      { category: "Help", label: _("API Help"),           url: help_page_path("api/README") },
      { category: "Help", label: _("Markdown Help"),      url: help_page_path("user/markdown") },
      { category: "Help", label: _("Permissions Help"),   url: help_page_path("user/permissions") },
      { category: "Help", label: _("Public Access Help"), url: help_page_path("public_access/public_access") },
      { category: "Help", label: _("Rake Tasks Help"),    url: help_page_path("raketasks/README") },
      { category: "Help", label: _("SSH Keys Help"),      url: help_page_path("ssh/README") },
      { category: "Help", label: _("System Hooks Help"),  url: help_page_path("system_hooks/system_hooks") },
      { category: "Help", label: _("Webhooks Help"),      url: help_page_path("user/project/integrations/webhooks") },
      { category: "Help", label: _("Workflow Help"),      url: help_page_path("workflow/README") }
    ]
  end

  # Autocomplete results for the current project, if it's defined
  def project_autocomplete
    if @project && @project.repository.exists? && @project.repository.root_ref
      ref = @ref || @project.repository.root_ref

      [
        { category: "In this project", label: _("Files"),          url: project_tree_path(@project, ref) },
        { category: "In this project", label: _("Commits"),        url: project_commits_path(@project, ref) },
        { category: "In this project", label: _("Network"),        url: project_network_path(@project, ref) },
        { category: "In this project", label: _("Graph"),          url: project_graph_path(@project, ref) },
        { category: "In this project", label: _("Issues"),         url: project_issues_path(@project) },
        { category: "In this project", label: _("Merge Requests"), url: project_merge_requests_path(@project) },
        { category: "In this project", label: _("Milestones"),     url: project_milestones_path(@project) },
        { category: "In this project", label: _("Snippets"),       url: project_snippets_path(@project) },
        { category: "In this project", label: _("Members"),        url: project_project_members_path(@project) },
        { category: "In this project", label: _("Wiki"),           url: project_wikis_path(@project) }
      ]
    else
      []
    end
  end

  # Autocomplete results for the current user's groups
  # rubocop: disable CodeReuse/ActiveRecord
  def groups_autocomplete(term, limit = 5)
    current_user.authorized_groups.order_id_desc.search(term).limit(limit).map do |group|
      {
        category: "Groups",
        id: group.id,
        label: "#{search_result_sanitize(group.full_name)}",
        url: group_path(group),
        avatar_url: group.avatar_url || ''
      }
    end
  end
  # rubocop: enable CodeReuse/ActiveRecord

  # Autocomplete results for the current user's projects
  # rubocop: disable CodeReuse/ActiveRecord
  def projects_autocomplete(term, limit = 5)
    current_user.authorized_projects.order_id_desc.search_by_title(term)
      .sorted_by_stars_desc.non_archived.limit(limit).map do |p|
      {
        category: "Projects",
        id: p.id,
        value: "#{search_result_sanitize(p.name)}",
        label: "#{search_result_sanitize(p.full_name)}",
        url: project_path(p),
        avatar_url: p.avatar_url || ''
      }
    end
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def search_result_sanitize(str)
    Sanitize.clean(str)
  end

  def search_filter_link(scope, label, data: {}, search: {})
    search_params = params
      .merge(search)
      .merge({ scope: scope })
      .permit(SEARCH_PERMITTED_PARAMS)

    if @scope == scope
      li_class = 'active'
      count = @search_results.formatted_count(scope)
    else
      badge_class = 'js-search-count hidden'
      badge_data = { url: search_count_path(search_params) }
    end

    content_tag :li, class: li_class, data: data do
      link_to search_path(search_params) do
        concat label
        concat ' '
        concat content_tag(:span, count, class: ['badge badge-pill', badge_class], data: badge_data)
      end
    end
  end

  def search_filter_input_options(type)
    opts =
      {
        id: "filtered-search-#{type}",
        placeholder: _('Search or filter results...'),
        data: {
          'username-params' => UserSerializer.new.represent(@users)
        },
        autocomplete: 'off'
      }

    opts[:data]['runner-tags-endpoint'] = tag_list_admin_runners_path

    if @project.present?
      opts[:data]['project-id'] = @project.id
      opts[:data]['labels-endpoint'] = project_labels_path(@project)
      opts[:data]['milestones-endpoint'] = project_milestones_path(@project)
      opts[:data]['releases-endpoint'] = project_releases_path(@project)
    elsif @group.present?
      opts[:data]['group-id'] = @group.id
      opts[:data]['labels-endpoint'] = group_labels_path(@group)
      opts[:data]['milestones-endpoint'] = group_milestones_path(@group)
    else
      opts[:data]['labels-endpoint'] = dashboard_labels_path
      opts[:data]['milestones-endpoint'] = dashboard_milestones_path
    end

    opts
  end

  def search_history_storage_prefix
    if @project.present?
      @project.full_path
    elsif @group.present?
      @group.full_path
    else
      'dashboard'
    end
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

  def show_user_search_tab?
    return false if Feature.disabled?(:users_search, default_enabled: true)

    if @project
      project_search_tabs?(:members)
    else
      can?(current_user, :read_users_list)
    end
  end
end

SearchHelper.prepend_if_ee('EE::SearchHelper')
