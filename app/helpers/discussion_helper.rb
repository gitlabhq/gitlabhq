module DiscussionHelper
  def part_of_discussion?(note)
    part_of_discussion = case note.noteable_type
                         when 'MergeRequest'
                           note.line_code.present?
                         when 'Commit'
                           true
                         else
                           false
                         end

    part_of_discussion && @show_discussions
  end

  def discussion_title(note)
    case note.noteable_type
    when 'MergeRequest'
      "#{note.author.name} started a discussion on this merge request (on line #{note.line_code.split('_')[2]}):"
    when 'Commit'
      if note.line_code.present?
        "#{note.author.name} started a discussion on commit #{link_to_commit_diff_line_note(note)}:"
      else
        "#{note.author.name} started a discussion on commit #{note.noteable_id}:"
      end
    else
      "#{note.author.name} started a discussion:"
    end
  end

  def render_discussion(note)
    unless discussions_for(note.noteable_type).include?(discussion_id_for(note))
      discussions_for(note.noteable_type).push(discussion_id_for(note))

      if note.line_note?
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

  def discussions_for(type)
    @discussions ||= { merge_requests: [], commits: [] }

    case type
    when 'MergeRequest'
      @discussions[:merge_requests]
    when 'Commit'
      @discussions[:commits]
    else
      []
    end
  end
end
