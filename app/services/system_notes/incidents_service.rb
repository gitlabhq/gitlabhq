# frozen_string_literal: true

module SystemNotes
  class IncidentsService < ::SystemNotes::BaseService
    CHANGED_TEXT = {
      occurred_at: 'the event time/date on ',
      note: 'the text on ',
      occurred_at_and_note: 'the event time/date and text on '
    }.freeze

    def initialize(noteable:)
      @noteable = noteable
      @project = noteable.project
    end

    def add_timeline_event(timeline_event)
      author = timeline_event.author
      anchor = "timeline_event_#{timeline_event.id}"
      path = url_helpers.project_issues_incident_path(project, noteable, anchor: anchor)
      body = "added an [incident timeline event](#{path})"

      create_note(NoteSummary.new(noteable, project, author, body, action: 'timeline_event'))
    end

    def edit_timeline_event(timeline_event, author, was_changed:)
      anchor = "timeline_event_#{timeline_event.id}"
      path = url_helpers.project_issues_incident_path(project, noteable, anchor: anchor)
      changed_text = CHANGED_TEXT.fetch(was_changed, '')
      body = "edited #{changed_text}[incident timeline event](#{path})"

      create_note(NoteSummary.new(noteable, project, author, body, action: 'timeline_event'))
    end

    def delete_timeline_event(author)
      body = 'deleted an incident timeline event'

      create_note(NoteSummary.new(noteable, project, author, body, action: 'timeline_event'))
    end
  end
end
