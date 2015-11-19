xml.instruct!
xml.feed "xmlns" => "http://www.w3.org/2005/Atom", "xmlns:media" => "http://search.yahoo.com/mrss/" do
  xml.title   "#{@project.name} activity"
  xml.link    href: namespace_project_url(@project.namespace, @project, format: :atom, private_token: current_user.try(:private_token)), rel: "self", type: "application/atom+xml"
  xml.link    href: namespace_project_url(@project.namespace, @project), rel: "alternate", type: "text/html"
  xml.id      namespace_project_url(@project.namespace, @project)
  xml.updated @events.latest_update_time.strftime("%Y-%m-%dT%H:%M:%SZ") if @events.any?

  @events.each do |event|
    event_to_atom(xml, event)
  end
end
