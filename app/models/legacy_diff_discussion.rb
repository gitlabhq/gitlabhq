# A discussion on merge request or commit diffs consisting of `LegacyDiffNote` notes.
# All new diff discussions are of the type `DiffDiscussion`, but any diff discussions created
# before the introduction of the new implementation still use `LegacyDiffDiscussion`.
class LegacyDiffDiscussion < Discussion
  include DiscussionOnDiff

  def legacy_diff_discussion?
    true
  end

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
