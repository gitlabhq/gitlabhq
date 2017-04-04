# A discussion to wrap a single `Note` note on the root of an issue, merge request,
# commit, or snippet, that is not displayed as a discussion.
class IndividualNoteDiscussion < Discussion
  def potentially_resolvable?
    false
  end

  def individual_note?
    true
  end
end
