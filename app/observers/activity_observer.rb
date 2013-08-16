class ActivityObserver < BaseObserver
  observe :issue, :note, :milestone

  def after_create(record)
    event_author_id = record.author_id

    if record.kind_of?(Note)
      # Skip system status notes like 'status changed to close'
      return true if record.note.include?("_Status changed to ")

      # Skip wall notes to prevent spamming of dashboard
      return true if record.noteable_type.blank?
    end

    if event_author_id
      create_event(record, Event.determine_action(record))
    end
  end

  def after_close(record, transition)
    create_event(record, Event::CLOSED)
  end

  def after_reopen(record, transition)
    create_event(record, Event::REOPENED)
  end

  protected

  def create_event(record, status)
    Event.create(
      project: record.project,
      target_id: record.id,
      target_type: record.class.name,
      action: status,
      author_id: current_user.id
    )
  end
end
