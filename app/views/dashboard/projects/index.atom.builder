xml.instruct!
xml.feed "xmlns" => "http://www.w3.org/2005/Atom", "xmlns:media" => "http://search.yahoo.com/mrss/" do
  xml.title   "Activity"
  xml.link    href: dashboard_projects_url(rss_url_options), rel: "self", type: "application/atom+xml"
  xml.link    href: dashboard_projects_url, rel: "alternate", type: "text/html"
  xml.id      dashboard_projects_url
  xml.updated @events[0].updated_at.xmlschema if @events[0]

  xml << render(partial: 'events/event', collection: @events) if @events.any?
end
