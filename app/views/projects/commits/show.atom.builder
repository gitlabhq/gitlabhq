xml.title   "#{@project.name}:#{@ref} commits"
xml.link    href: project_commits_url(@project, @ref, rss_url_options), rel: "self", type: "application/atom+xml"
xml.link    href: project_commits_url(@project, @ref), rel: "alternate", type: "text/html"
xml.id      project_commits_url(@project, @ref)
xml.updated @commits.first.committed_date.xmlschema if @commits.any?

xml << render(@commits) if @commits.any?
