# frozen_string_literal: true

xml.title   "#{@project.name} tags"
xml.link    href: project_tags_url(@project, @ref, rss_url_options), rel: 'self', type: 'application/atom+xml'
xml.link    href: project_tags_url(@project, @ref), rel: 'alternate', type: 'text/html'
xml.id      project_tags_url(@project, @ref)
xml.updated @releases.first.updated_at.xmlschema if @releases.any?

xml << render(partial: 'tag', collection: @tags) if @tags.any?
