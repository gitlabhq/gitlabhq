class ActivityObserver < ActiveRecord::Observer
  observe :issue, :merge_request, :note, :milestone

  def after_create(record)
    event_author_id = record.author_id

    # Skip status notes
    if record.kind_of?(Note) && record.note.include?("_Status changed to ")
      return true
    end

    if event_author_id
      Event.create(
        project: record.project,
        target_id: record.id,
        target_type: record.class.name,
        action: Event.determine_action(record),
        author_id: event_author_id
      )
    end
  end

  def after_close(record, transition)
      Event.create(
        project: record.project,
        target_id: record.id,
        target_type: record.class.name,
        action: Event::CLOSED,
        author_id: record.author_id_of_changes
      )
  end

  def after_reopen(record, transition)
      Event.create(
        project: record.project,
        target_id: record.id,
        target_type: record.class.name,
        action: Event::REOPENED,
        author_id: record.author_id_of_changes
      )
  end
end
