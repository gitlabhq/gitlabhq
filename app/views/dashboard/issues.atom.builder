xml.instruct!
xml.feed "xmlns" => "http://www.w3.org/2005/Atom", "xmlns:media" => "http://search.yahoo.com/mrss/" do
  xml.title   "#{current_user.name} issues"
  xml.link    href: url_for(params), rel: "self", type: "application/atom+xml"
  xml.link    href: issues_dashboard_url, rel: "alternate", type: "text/html"
  xml.id      issues_dashboard_url
  xml.updated @issues.first.created_at.xmlschema if @issues.reorder(nil).any?

  xml << render(partial: 'issues/issue', collection: @issues) if @issues.reorder(nil).any?
end
