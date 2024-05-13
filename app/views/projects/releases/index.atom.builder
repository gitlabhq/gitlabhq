# frozen_string_literal: true

xml.title   "#{@project.name} releases"
xml.link    href: project_releases_url(@project, rss_url_options), rel: "self", type: "application/atom+xml"
xml.link    href: project_releases_url(@project), rel: "alternate", type: "text/html"
xml.id      project_releases_url(@project)
xml.updated @releases.latest.updated_at.xmlschema if @releases.any?

xml << render(partial: 'release', collection: @releases) if @releases.any?
