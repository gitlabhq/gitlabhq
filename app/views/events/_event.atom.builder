# frozen_string_literal: true

return unless event.visible_to_user?(current_user)

event = event.present
event_url = event_feed_url(event)

xml.entry do
  xml.id      "tag:#{request.host},#{event.created_at.strftime("%Y-%m-%d")}:#{event.id}"
  xml.link    href: event_url if event_url
  xml.title   truncate(event_feed_title(event), length: 80)
  xml.updated event.updated_at.xmlschema

  # We're deliberately re-using "event.author" here since this data is
  # eager-loaded. This allows us to re-use the user object's Email address,
  # instead of having to run additional queries to figure out what Email to use
  # for the avatar.
  xml.media   :thumbnail, width: "40", height: "40", url: image_url(avatar_icon_for_user(event.author))

  xml.author do
    xml.username event.author_username
    xml.name event.author_name
    xml.email event.author_public_email
  end

  xml.summary(type: "xhtml") do |summary|
    event_summary = event_feed_summary(event)

    summary << event_summary unless event_summary.nil?
  end
end
