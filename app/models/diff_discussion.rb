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

            to: :first_note

  def legacy_diff_discussion?
    false
  end

  def merge_request_version_params
    return unless for_merge_request?

    if active?
      {}
    else
      diff_refs = position.diff_refs

      if diff = noteable.merge_request_diff_for(diff_refs)
        { diff_id: diff.id }
      elsif diff = noteable.merge_request_diff_for(diff_refs.head_sha)
        {
          diff_id: diff.id,
          start_sha: diff_refs.start_sha
        }
      end
    end
  end

  def reply_attributes
    super.merge(
      original_position: original_position.to_json,
      position: position.to_json,
    )
  end
end
