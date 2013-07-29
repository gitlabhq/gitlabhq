class ActivityObserver < BaseObserver
  observe :issue, :merge_request, :note, :milestone

  def after_create(record)
    event_author_id = record.author_id

    if record.kind_of?(Note)
      # Skip system status notes like 'status changed to close'
      return true if record.note.include?("_Status changed to ")

      # Skip wall notes to prevent spamming of dashboard
      return true if record.noteable_type.blank?
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

  def after_merge(record, transition)
    # Since MR can be merged via sidekiq
    # to prevent event duplication do this check
    return true if record.merge_event

    Event.create(
      project: record.project,
      target_id: record.id,
      target_type: record.class.name,
      action: Event::MERGED,
      author_id: record.author_id_of_changes
    )
  end
end
