# frozen_string_literal: true

xml.title   "Activity"
xml.link    href: dashboard_projects_url(rss_url_options), rel: "self", type: "application/atom+xml"
xml.link    href: dashboard_projects_url, rel: "alternate", type: "text/html"
xml.id      dashboard_projects_url
xml.updated @events[0].updated_at.xmlschema if @events[0]

xml << render(partial: 'events/event', collection: @events) if @events.any?
