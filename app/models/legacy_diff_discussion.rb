# A discussion on merge request or commit diffs consisting of `LegacyDiffNote` notes
class LegacyDiffDiscussion < Discussion
  include DiscussionOnDiff

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
