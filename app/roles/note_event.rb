module NoteEvent
  def note_commit_id
    target.noteable_id
  end

  def note_short_commit_id
    note_commit_id[0..8]
  end

  def note_commit?
    target.noteable_type == "Commit"
  end

  def note_target
    target.noteable
  end

  def note_target_id
    target.noteable_id
  end
end
