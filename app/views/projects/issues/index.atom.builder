xml.instruct!
xml.feed "xmlns" => "http://www.w3.org/2005/Atom", "xmlns:media" => "http://search.yahoo.com/mrss/" do
  xml.title   "#{@project.name} issues"
  xml.link    href: namespace_project_issues_url(@project.namespace, @project, format: :atom, private_token: current_user.try(:private_token)), rel: "self", type: "application/atom+xml"
  xml.link    href: namespace_project_issues_url(@project.namespace, @project), rel: "alternate", type: "text/html"
  xml.id      namespace_project_issues_url(@project.namespace, @project)
  xml.updated @issues.first.created_at.xmlschema if @issues.any?

  @issues.each do |issue|
    issue_to_atom(xml, issue)
  end
end
