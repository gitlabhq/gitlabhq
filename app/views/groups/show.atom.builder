xml.instruct!
xml.feed "xmlns" => "http://www.w3.org/2005/Atom", "xmlns:media" => "http://search.yahoo.com/mrss/" do
  xml.title   "#{@group.name} activity"
  xml.link    href: group_url(@group, rss_url_options), rel: "self", type: "application/atom+xml"
  xml.link    href: group_url(@group), rel: "alternate", type: "text/html"
  xml.id      group_url(@group)
  xml.updated @events[0].updated_at.xmlschema if @events[0]

  xml << render(@events) if @events.any?
end
