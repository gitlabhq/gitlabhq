# frozen_string_literal: true

# A discussion to wrap a single `Note` note on the root of an issue, merge request,
# commit, or snippet, that is not displayed as a discussion.
#
# A discussion of this type is never resolvable.
class IndividualNoteDiscussion < Discussion
  def self.note_class
    Note
  end

  def individual_note?
    true
  end

  def can_convert_to_discussion?
    noteable.supports_replying_to_individual_notes?
  end

  def convert_to_discussion!
    first_note.becomes!(Discussion.note_class).to_discussion
  end

  def reply_attributes
    super.tap { |attrs| attrs.delete(:discussion_id) }
  end
end
