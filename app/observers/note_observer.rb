class NoteObserver < BaseObserver
  def after_create(note)
    notification.new_note(note)

    # Skip system notes, like status changes and cross-references.
    # Skip wall notes to prevent spamming of dashboard
    if note.noteable_type.present? && !note.system
      event_service.leave_note(note, note.author)
    end

    unless note.system?
      # Create a cross-reference note if this Note contains GFM that names an
      # issue, merge request, or commit.
      note.references.each do |mentioned|
        Note.create_cross_reference_note(mentioned, note.noteable, note.author, note.project)
      end
    end
  end

  def after_update(note)
    note.notice_added_references(note.project, note.author)
  end
end
