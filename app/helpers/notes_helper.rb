module NotesHelper
  def loading_more_notes?
    params[:loading_more].present?
  end

  def loading_new_notes?
    params[:loading_new].present?
  end

  def note_vote_class(note)
    if note.upvote?
      "vote upvote"
    elsif note.downvote?
      "vote downvote"
    end
  end

  def emoji_for_completion
    # should be an array of strings
    # so to_s can be called, because it is sufficient and to_json is too slow
    Emoji::NAMES
  end
end
