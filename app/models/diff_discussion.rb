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
            :change_position,
            :on_text?,
            :on_image?,

            to: :first_note

  def legacy_diff_discussion?
    false
  end

  def merge_request_version_params
    return unless for_merge_request?
    return {} if active?

    noteable.version_params_for(position.diff_refs)
  end

  def reply_attributes
    super.merge(
      original_position: original_position.to_json,
      position: position.to_json
    )
  end
end
