# frozen_string_literal: true

# When notes on a commit are displayed in the context of a merge request that
# contains that commit, they are displayed as if they were a discussion.
#
# This represents one of those discussions, consisting of `Note` notes.
#
# A discussion of this type is never resolvable.
class OutOfContextDiscussion < Discussion
  # Returns an array of discussion ID components
  def self.build_discussion_id(note)
    base_discussion_id(note)
  end

  # To make sure all out-of-context notes end up grouped as one discussion,
  # we override the discussion ID to be a newly generated but consistent ID.
  def self.override_discussion_id(note)
    discussion_id(note)
  end

  def self.note_class
    Note
  end

  def reply_attributes
    super.tap { |attrs| attrs.delete(:discussion_id) }
  end
end
