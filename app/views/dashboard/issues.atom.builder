xml.instruct!
xml.feed "xmlns" => "http://www.w3.org/2005/Atom", "xmlns:media" => "http://search.yahoo.com/mrss/" do
  xml.title   "#{current_user.name} issues"
  xml.link    href: issues_dashboard_url(format: :atom, private_token: current_user.try(:private_token)), rel: "self", type: "application/atom+xml"
  xml.link    href: issues_dashboard_url, rel: "alternate", type: "text/html"
  xml.id      issues_dashboard_url
  xml.updated @issues.first.created_at.xmlschema if @issues.any?

  @issues.each do |issue|
    issue_to_atom(xml, issue)
  end
end

