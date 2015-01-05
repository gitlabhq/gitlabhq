xml.instruct!
xml.feed "xmlns" => "http://www.w3.org/2005/Atom", "xmlns:media" => "http://search.yahoo.com/mrss/" do
  xml.title   "#{@project.name} issues"
  xml.link    :href => project_issues_url(@project, :atom), :rel => "self", :type => "application/atom+xml"
  xml.link    :href => project_issues_url(@project), :rel => "alternate", :type => "text/html"
  xml.id      project_issues_url(@project)
  xml.updated @issues.first.created_at.strftime("%Y-%m-%dT%H:%M:%SZ") if @issues.any?

  @issues.each do |issue|
    issue_to_atom(xml, issue)
  end
end
