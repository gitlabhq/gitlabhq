module DiscussionHelper
  def part_of_discussion?(note)
    note.for_commit? || note.for_merge_request_diff_line?
  end

  def discussion_title(note)
    if note.for_merge_request?
      "#{note.author.name} started a discussion on this merge request (on line #{note.diff_new_line}):"
    elsif note.for_commit_diff_line?
      "#{note.author.name} started a discussion on commit #{link_to_commit_diff_line_note(note)}:"
    elsif note.for_commit?
      "#{note.author.name} started a discussion on commit #{note.noteable_id}:"
    else
      "#{note.author.name} started a discussion:"
    end
  end

  def render_discussion(note)
    unless discussions_for(note).include?(discussion_id_for(note))
      discussions_for(note).push(discussion_id_for(note))

      if note.for_diff_line?
        @reply_allowed = true
        @line_notes = discussion_notes(note)
        render 'discussion', note: note, diff: note.diff
      else
        render 'discussion', note: note
      end
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
