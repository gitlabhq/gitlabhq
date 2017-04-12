# A discussion on merge request or commit diffs consisting of `DiffNote` notes.
#
# A discussion of this type can be resolvable.
class DiffDiscussion < Discussion
  include DiscussionOnDiff

  def self.note_class
    DiffNote
  end

  delegate  :position,
            :original_position,
            :latest_merge_request_diff,

            to: :first_note

  def legacy_diff_discussion?
    false
  end

  def reply_attributes
    super.merge(
      original_position: original_position.to_json,
      position: position.to_json,
    )
  end
end
