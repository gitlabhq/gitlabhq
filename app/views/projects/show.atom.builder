xml.title   "#{@project.name} activity"
xml.link    href: namespace_project_url(*@project, rss_url_options), rel: "self", type: "application/atom+xml"
xml.link    href: namespace_project_url(*@project), rel: "alternate", type: "text/html"
xml.id      namespace_project_url(*@project)
xml.updated @events[0].updated_at.xmlschema if @events[0]

xml << render(@events) if @events.any?
