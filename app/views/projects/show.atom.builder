xml.instruct!
xml.feed "xmlns" => "http://www.w3.org/2005/Atom", "xmlns:media" => "http://search.yahoo.com/mrss/" do
  xml.title   "#{@project.name} activity"
  xml.link    href: namespace_project_url(@project.namespace, @project, format: :atom, private_token: current_user.try(:private_token)), rel: "self", type: "application/atom+xml"
  xml.link    href: namespace_project_url(@project.namespace, @project), rel: "alternate", type: "text/html"
  xml.id      namespace_project_url(@project.namespace, @project)
  xml.updated @events[0].updated_at.xmlschema if @events[0]

  xml << render(@events) if @events.any?
end
