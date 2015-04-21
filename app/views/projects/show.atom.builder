xml.instruct!
xml.feed "xmlns" => "http://www.w3.org/2005/Atom", "xmlns:media" => "http://search.yahoo.com/mrss/" do
  xml.title   "Project feed - #{@project.name}"
  xml.link    href: namespace_project_path(@project.namespace, @project, :atom), rel: "self", type: "application/atom+xml"
  xml.link    href: namespace_project_path(@project.namespace, @project), rel: "alternate", type: "text/html"
  xml.id      projects_url
  xml.updated @events.maximum(:updated_at).strftime("%Y-%m-%dT%H:%M:%SZ") if @events.any?

  @events.each do |event|
    event_to_atom(xml, event)
  end
end
