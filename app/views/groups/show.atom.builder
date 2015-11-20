xml.instruct!
xml.feed "xmlns" => "http://www.w3.org/2005/Atom", "xmlns:media" => "http://search.yahoo.com/mrss/" do
  xml.title   "#{@group.name} activity"
  xml.link    href: group_url(@group, format: :atom, private_token: current_user.try(:private_token)), rel: "self", type: "application/atom+xml"
  xml.link    href: group_url(@group), rel: "alternate", type: "text/html"
  xml.id      group_url(@group)
  xml.updated @events.latest_update_time.strftime("%Y-%m-%dT%H:%M:%SZ") if @events.any?

  @events.each do |event|
    event_to_atom(xml, event)
  end
end
