class DiffDiscussion < Discussion
  include DiscussionOnDiff

  delegate  :position,
            :original_position,

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
