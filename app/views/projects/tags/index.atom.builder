# frozen_string_literal: true

first_tag_commit = @repository.commit(@tags.first.dereferenced_target) if @tags.any?

xml.title   "#{@project.name} tags"
xml.link    href: project_tags_url(@project, @ref, rss_url_options), rel: 'self', type: 'application/atom+xml'
xml.link    href: project_tags_url(@project, @ref), rel: 'alternate', type: 'text/html'
xml.id      project_tags_url(@project, @ref)
xml.updated first_tag_commit.committed_date.xmlschema if first_tag_commit

xml << render(partial: 'tag', collection: @tags) if @tags.any?
