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

  def search_entries_info(collection, scope, term)
    return unless collection.count > 0

    from = collection.offset_value + 1
    to = collection.offset_value + collection.length
    count = collection.total_count

    "显示 \"#{term}\" 的 #{from} - #{to} / #{count} #{scope.humanize(capitalize: false)}"
  end

  private

  # Autocomplete results for various settings pages
  def default_autocomplete
    [
      { category: "设置", label: "个人资料设置", url: profile_path },
      { category: "设置", label: "SSH 密钥",         url: profile_keys_path },
      { category: "设置", label: "仪表盘",        url: root_path },
      { category: "设置", label: "管理后台",    url: admin_root_path },
    ]
  end

  # Autocomplete results for internal help pages
  def help_autocomplete
    [
      { category: "帮助", label: "API 帮助",           url: help_page_path("api", "README") },
      { category: "帮助", label: "Markdown 帮助",      url: help_page_path("markdown", "markdown") },
      { category: "帮助", label: "权限帮助",   url: help_page_path("permissions", "permissions") },
      { category: "帮助", label: "公开访问帮助", url: help_page_path("public_access", "public_access") },
      { category: "帮助", label: "Rake 任务帮助",    url: help_page_path("raketasks", "README") },
      { category: "帮助", label: "SSH 密钥帮助",      url: help_page_path("ssh", "README") },
      { category: "帮助", label: "系统钩子帮助",  url: help_page_path("system_hooks", "system_hooks") },
      { category: "帮助", label: "Web 钩子帮助",      url: help_page_path("web_hooks", "web_hooks") },
      { category: "帮助", label: "工作流帮助",      url: help_page_path("workflow", "README") },
    ]
  end

  # Autocomplete results for the current project, if it's defined
  def project_autocomplete
    if @project && @project.repository.exists? && @project.repository.root_ref
      ref = @ref || @project.repository.root_ref

      [
        { category: "当前项目", label: "文件",          url: namespace_project_tree_path(@project.namespace, @project, ref) },
        { category: "当前项目", label: "提交",        url: namespace_project_commits_path(@project.namespace, @project, ref) },
        { category: "当前项目", label: "网络",        url: namespace_project_network_path(@project.namespace, @project, ref) },
        { category: "当前项目", label: "图表",          url: namespace_project_graph_path(@project.namespace, @project, ref) },
        { category: "当前项目", label: "问题",         url: namespace_project_issues_path(@project.namespace, @project) },
        { category: "当前项目", label: "合并请求", url: namespace_project_merge_requests_path(@project.namespace, @project) },
        { category: "当前项目", label: "里程碑",     url: namespace_project_milestones_path(@project.namespace, @project) },
        { category: "当前项目", label: "代码片段",       url: namespace_project_snippets_path(@project.namespace, @project) },
        { category: "当前项目", label: "成员",        url: namespace_project_project_members_path(@project.namespace, @project) },
        { category: "当前项目", label: "维基",           url: namespace_project_wikis_path(@project.namespace, @project) },
      ]
    else
      []
    end
  end

  # Autocomplete results for the current user's groups
  def groups_autocomplete(term, limit = 5)
    current_user.authorized_groups.search(term).limit(limit).map do |group|
      {
        category: "群组",
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
        category: "项目",
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
