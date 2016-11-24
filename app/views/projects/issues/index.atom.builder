xml.instruct!
xml.feed "xmlns" => "http://www.w3.org/2005/Atom", "xmlns:media" => "http://search.yahoo.com/mrss/" do
  xml.title   "#{@project.name} issues"
  xml.link    href: url_for(params), rel: "self", type: "application/atom+xml"
  xml.link    href: namespace_project_issues_url(@project.namespace, @project), rel: "alternate", type: "text/html"
  xml.id      namespace_project_issues_url(@project.namespace, @project)
  xml.updated @issues.first.created_at.xmlschema if @issues.reorder(nil).any?

  xml << render(partial: 'issues/issue', collection: @issues) if @issues.reorder(nil).any?
end
