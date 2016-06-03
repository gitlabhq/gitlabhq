xml.instruct!
xml.feed "xmlns" => "http://www.w3.org/2005/Atom", "xmlns:media" => "http://search.yahoo.com/mrss/" do
  xml.title   "#{@user.name} activity"
  xml.link    href: user_url(@user, :atom), rel: "self", type: "application/atom+xml"
  xml.link    href: user_url(@user), rel: "alternate", type: "text/html"
  xml.id      user_url(@user)
  xml.updated @events[0].updated_at.xmlschema if @events[0]

  @events.each do |event|
    event_to_atom(xml, event)
  end
end
