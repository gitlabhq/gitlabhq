return unless event.visible_to_user?(current_user)

xml.entry do
  xml.id      "tag:#{request.host},#{event.created_at.strftime("%Y-%m-%d")}:#{event.id}"
  xml.link    href: event_feed_url(event)
  xml.title   truncate(event_feed_title(event), length: 80)
  xml.updated event.created_at.xmlschema
  xml.media   :thumbnail, width: "40", height: "40", url: image_url(avatar_icon(event.author_email))

  xml.author do
    xml.name event.author_name
    xml.email event.author_email
  end

  xml.summary(type: "xhtml") do |summary|
    event_summary = event_feed_summary(event)

    summary << event_summary unless event_summary.nil?
  end
end
