module DiscussionHelper
  def part_of_discussion?(note)
    note.for_commit? || note.for_merge_request_diff_line?
  end

  def has_rendered?(note)
    discussions_for(note).include?(discussion_id_for(note))
  end

  def discussion_rendered!(note)
    discussions_for(note).push(discussion_id_for(note))
  end

  def discussion_params(note)
    if note.for_diff_line?
      @reply_allowed = true
      @line_notes = discussion_notes(note)
      { note: note, diff: note.diff }
    else
      { note: note }
    end
  end

  def discussion_notes(note)
    @notes.select do |other_note|
      discussion_id_for(note) == discussion_id_for(other_note)
    end
  end

  def discussion_id_for(note)
    [note.line_code, note.noteable_id, note.noteable_type]
  end

  def discussions_for(note)
    @discussions ||= { merge_requests: [], commits: [] }

    if note.for_merge_request?
      @discussions[:merge_requests]
    elsif note.for_commit?
      @discussions[:commits]
    else
      []
    end
  end
end
