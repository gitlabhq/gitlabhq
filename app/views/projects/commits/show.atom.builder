xml.title   "#{@project.name}:#{@ref} commits"
xml.link    href: namespace_project_commits_url(@project.namespace, @project, @ref, rss_url_options), rel: "self", type: "application/atom+xml"
xml.link    href: namespace_project_commits_url(@project.namespace, @project, @ref), rel: "alternate", type: "text/html"
xml.id      namespace_project_commits_url(@project.namespace, @project, @ref)
xml.updated @commits.first.committed_date.xmlschema if @commits.any?

xml << render(@commits) if @commits.any?
