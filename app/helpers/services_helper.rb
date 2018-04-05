module ServicesHelper
<<<<<<< HEAD
  prepend EE::ServicesHelper
=======
  def service_event_description(event)
    case event
    when "push", "push_events"
      "Event will be triggered by a push to the repository"
    when "tag_push", "tag_push_events"
      "Event will be triggered when a new tag is pushed to the repository"
    when "note", "note_events"
      "Event will be triggered when someone adds a comment"
    when "confidential_note", "confidential_note_events"
      "Event will be triggered when someone adds a comment on a confidential issue"
    when "issue", "issue_events"
      "Event will be triggered when an issue is created/updated/closed"
    when "confidential_issue", "confidential_issues_events"
      "Event will be triggered when a confidential issue is created/updated/closed"
    when "merge_request", "merge_request_events"
      "Event will be triggered when a merge request is created/updated/merged"
    when "pipeline", "pipeline_events"
      "Event will be triggered when a pipeline status changes"
    when "wiki_page", "wiki_page_events"
      "Event will be triggered when a wiki page is created/updated"
    when "commit", "commit_events"
      "Event will be triggered when a commit is created/updated"
    end
  end
>>>>>>> upstream/master

  def service_event_field_name(event)
    event = event.pluralize if %w[merge_request issue confidential_issue].include?(event)
    "#{event}_events"
  end

  def service_save_button(service)
    button_tag(class: 'btn btn-save', type: 'submit', disabled: service.deprecated?) do
      icon('spinner spin', class: 'hidden js-btn-spinner') +
        content_tag(:span, 'Save changes', class: 'js-btn-label')
    end
  end

  def disable_fields_service?(service)
    !current_controller?("admin/services") && service.deprecated?
  end

  extend self
end
