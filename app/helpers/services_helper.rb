module ServicesHelper
  def service_event_description(event)
    case event
    when "push"
      "Event will be triggered by a push to the repository"
    when "tag_push"
      "Event will be triggered when a new tag is pushed to the repository"
    when "note"
      "Event will be triggered when someone adds a comment"
    when "issue"
      "Event will be triggered when an issue is created/updated/merged"
    when "merge_request"
      "Event will be triggered when a merge request is created/updated/merged"
    when "build"
      "Event will be triggered when a build status changes"
    when "wiki_page"
      "Event will be triggered when a wiki page is created/updated"
    end
  end

  def service_event_field_name(event)
    event = event.pluralize if %w[merge_request issue].include?(event)
    "#{event}_events"
  end
end
