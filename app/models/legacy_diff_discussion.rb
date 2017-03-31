class LegacyDiffDiscussion < Discussion
  include DiscussionOnDiff

  def self.build_discussion_id(note)
    [*super(note), note.line_code]
  end

  def legacy_diff_discussion?
    true
  end

  # Keep this method in sync with the `potentially_resolvable` scope on `ResolvableNote`
  def potentially_resolvable?
    false
  end

  def collapsed?
    !active?
  end

  def reply_attributes
    super.merge(line_code: line_code)
  end
end
