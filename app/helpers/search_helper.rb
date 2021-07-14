# frozen_string_literal: true

module SearchHelper
  SEARCH_GENERIC_PARAMS = [
    :search,
    :scope,
    :project_id,
    :group_id,
    :repository_ref,
    :snippets,
    :sort,
    :force_search_results,
    :project_ids
  ].freeze

  def search_autocomplete_opts(term)
    return unless current_user

    resources_results = [
      recent_items_autocomplete(term),
      groups_autocomplete(term),
      projects_autocomplete(term),
      issue_autocomplete(term)
    ].flatten

    search_pattern = Regexp.new(Regexp.escape(term), "i")

    generic_results = project_autocomplete + default_autocomplete + help_autocomplete
    generic_results.concat(default_autocomplete_admin) if current_user.admin?
    generic_results.select! { |result| result[:label] =~ search_pattern }

    [
      resources_results,
      generic_results
    ].flatten do |item|
      item[:label]
    end
  end

  def recent_items_autocomplete(term)
    recent_merge_requests_autocomplete(term) + recent_issues_autocomplete(term)
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

  def search_entries_empty_message(scope, term, group, project)
    options = {
      scope: search_entries_scope_label(scope, 0),
      term: "<code>#{h(term)}</code>".html_safe
    }

    # We check project first because we have 3 possible combinations here:
    # - group && project
    # - group
    # - group: nil, project: nil
    if project
      html_escape(_("We couldn't find any %{scope} matching %{term} in project %{project}")) % options.merge(
        project: link_to(project.full_name, project_path(project), target: '_blank', rel: 'noopener noreferrer').html_safe
      )
    elsif group
      html_escape(_("We couldn't find any %{scope} matching %{term} in group %{group}")) % options.merge(
        group: link_to(group.full_name, group_path(group), target: '_blank', rel: 'noopener noreferrer').html_safe
      )
    else
      html_escape(_("We couldn't find any %{scope} matching %{term}")) % options
    end
  end

  def repository_ref(project)
    # Always #to_s the repository_ref param in case the value is also a number
    params[:repository_ref].to_s.presence || project.default_branch
  end

  # Overridden in EE
  def search_blob_title(project, path)
    path
  end

  def search_service
    @search_service ||= ::SearchService.new(current_user, params.merge(confidential: Gitlab::Utils.to_boolean(params[:confidential])))
  end

  def search_sort_options
    options = [
      {
        title: _('Created date'),
        sortable: true,
        sortParam: {
          asc: 'created_asc',
          desc: 'created_desc'
        }
      },
      {
        title: _('Last updated'),
        sortable: true,
        sortParam: {
          asc: 'updated_asc',
          desc: 'updated_desc'
        }
      }
    ]

    if search_service.scope == 'issues' && Feature.enabled?(:search_sort_issues_by_popularity)
      options << {
        title: _('Popularity'),
        sortable: true,
        sortParam: {
          asc: 'popularity_asc',
          desc: 'popularity_desc'
        }
      }
    end

    options
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
      { category: "Help", label: _("API Help"),           url: help_page_path("api/index") },
      { category: "Help", label: _("Markdown Help"),      url: help_page_path("user/markdown") },
      { category: "Help", label: _("Permissions Help"),   url: help_page_path("user/permissions") },
      { category: "Help", label: _("Public Access Help"), url: help_page_path("public_access/public_access") },
      { category: "Help", label: _("Rake Tasks Help"),    url: help_page_path("raketasks/README") },
      { category: "Help", label: _("SSH Keys Help"),      url: help_page_path("ssh/index") },
      { category: "Help", label: _("System Hooks Help"),  url: help_page_path("system_hooks/system_hooks") },
      { category: "Help", label: _("Webhooks Help"),      url: help_page_path("user/project/integrations/webhooks") }
    ]
  end

  # Autocomplete results for the current project, if it's defined
  def project_autocomplete
    if @project && @project.repository.root_ref
      ref = @ref || @project.repository.root_ref

      result = [
        { category: "In this project", label: _("Files"),          url: project_tree_path(@project, ref) },
        { category: "In this project", label: _("Commits"),        url: project_commits_path(@project, ref) },
        { category: "In this project", label: _("Network"),        url: project_network_path(@project, ref) },
        { category: "In this project", label: _("Graph"),          url: project_graph_path(@project, ref) },
        { category: "In this project", label: _("Issues"),         url: project_issues_path(@project) },
        { category: "In this project", label: _("Merge requests"), url: project_merge_requests_path(@project) },
        { category: "In this project", label: _("Milestones"),     url: project_milestones_path(@project) },
        { category: "In this project", label: _("Snippets"),       url: project_snippets_path(@project) },
        { category: "In this project", label: _("Members"),        url: project_project_members_path(@project) },
        { category: "In this project", label: _("Wiki"),           url: project_wikis_path(@project) }
      ]

      if can?(current_user, :read_feature_flag, @project)
        result << { category: "In this project", label: _("Feature Flags"), url: project_feature_flags_path(@project) }
      end

      result
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

  def issue_autocomplete(term)
    return [] unless @project.present? && current_user && term =~ /\A#{Issue.reference_prefix}\d+\z/

    iid = term.sub(Issue.reference_prefix, '').to_i
    issue = @project.issues.find_by_iid(iid)
    return [] unless issue && Ability.allowed?(current_user, :read_issue, issue)

    [
        {
            category: 'In this project',
            id: issue.id,
            label: search_result_sanitize("#{issue.title} (#{issue.to_reference})"),
            url: issue_path(issue),
            avatar_url: issue.project.avatar_url || ''
        }
    ]
  end

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

  def recent_merge_requests_autocomplete(term)
    return [] unless current_user

    ::Gitlab::Search::RecentMergeRequests.new(user: current_user).search(term).map do |mr|
      {
        category: "Recent merge requests",
        id: mr.id,
        label: search_result_sanitize(mr.title),
        url: merge_request_path(mr),
        avatar_url: mr.project.avatar_url || ''
      }
    end
  end

  def recent_issues_autocomplete(term)
    return [] unless current_user

    ::Gitlab::Search::RecentIssues.new(user: current_user).search(term).map do |i|
      {
        category: "Recent issues",
        id: i.id,
        label: search_result_sanitize(i.title),
        url: issue_path(i),
        avatar_url: i.project.avatar_url || ''
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
      .permit(SEARCH_GENERIC_PARAMS)

    if @scope == scope
      li_class = 'active'
      count = @timeout ? 0 : @search_results.formatted_count(scope)
    else
      badge_class = 'js-search-count hidden'
      badge_data = { url: search_count_path(search_params) }
    end

    content_tag :li, class: li_class, data: data do
      link_to search_path(search_params) do
        concat label
        concat ' '
        concat content_tag(:span, count, class: ['badge badge-pill gl-badge badge-muted sm', badge_class], data: badge_data)
      end
    end
  end

  def search_filter_input_options(type, placeholder = _('Search or filter results...'))
    opts =
      {
        id: "filtered-search-#{type}",
        placeholder: placeholder,
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
      opts[:data]['environments-endpoint'] =
        unfoldered_environment_names_project_path(@project)
    elsif @group.present?
      opts[:data]['group-id'] = @group.id
      opts[:data]['labels-endpoint'] = group_labels_path(@group)
      opts[:data]['milestones-endpoint'] = group_milestones_path(@group)
      opts[:data]['releases-endpoint'] = group_releases_path(@group)
      opts[:data]['environments-endpoint'] =
        unfoldered_environment_names_group_path(@group)
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

  def search_md_sanitize(source)
    search_sanitize(markdown(search_truncate(source)))
  end

  def simple_search_highlight_and_truncate(text, phrase, options = {})
    highlight(search_sanitize(search_truncate(text)), phrase.split, options)
  end

  # Sanitize a HTML field for search display. Most tags are stripped out and the
  # maximum length is set to 200 characters.
  def search_truncate(source)
    Truncato.truncate(
      source,
      count_tags: false,
      count_tail: false,
      filtered_tags: %w(img),
      max_length: 200
    )
  end

  def search_sanitize(html)
    # Truncato's filtered_tags and filtered_attributes are not quite the same
    sanitize(html, tags: %w(a p ol ul li pre code))
  end

  # _search_highlight is used in EE override
  def highlight_and_truncate_issuable(issuable, search_term, _search_highlight)
    return unless issuable.description.present?

    simple_search_highlight_and_truncate(issuable.description, search_term, highlighter: '<span class="gl-text-gray-900 gl-font-weight-bold">\1</span>')
  end

  def show_user_search_tab?
    if @project
      project_search_tabs?(:members)
    else
      can?(current_user, :read_users_list)
    end
  end

  def issuable_state_to_badge_class(issuable)
    # Closed is considered "danger" for MR so we need to handle separately
    if issuable.is_a?(::MergeRequest)
      if issuable.merged?
        :info
      elsif issuable.closed?
        :danger
      else
        :success
      end
    else
      if issuable.closed?
        :info
      else
        :success
      end
    end
  end

  def issuable_state_text(issuable)
    case issuable.state
    when 'merged'
      _("Merged")
    when 'closed'
      _("Closed")
    else
      _("Open")
    end
  end
end

SearchHelper.prepend_mod_with('SearchHelper')
