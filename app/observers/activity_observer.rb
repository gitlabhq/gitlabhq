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

  def after_save(record)
    if record.changed.include?("closed") && record.author_id_of_changes
      Event.create(
        project: record.project,
        target_id: record.id,
        target_type: record.class.name,
        action: (record.closed ? Event::Closed : Event::Reopened),
        author_id: record.author_id_of_changes
      )
    end
  end
end
