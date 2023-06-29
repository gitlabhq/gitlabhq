# frozen_string_literal: true

xml.title   @topic.name
xml.link    href: topic_explore_projects_url(@topic.name, rss_url_options), rel: "self", type: "application/atom+xml"
xml.link    href: topic_explore_projects_url(@topic.name), rel: "alternate", type: "text/html"
xml.id      topic_explore_projects_url(@topic.id)
xml.updated @projects[0].updated_at.xmlschema if @projects[0]

xml << render(@projects) if @projects.any?
