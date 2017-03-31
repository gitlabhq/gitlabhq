class DiffDiscussion < Discussion
  include DiscussionOnDiff

  delegate  :position,
            :original_position,

            to: :first_note

  def self.build_discussion_id(note)
    [*super(note), *note.position.key]
  end

  def self.build_original_discussion_id(note)
    [*Discussion.build_discussion_id(note), *note.original_position.key]
  end

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
