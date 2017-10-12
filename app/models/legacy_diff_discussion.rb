# A discussion on merge request or commit diffs consisting of `LegacyDiffNote` notes.
#
# All new diff discussions are of the type `DiffDiscussion`, but any diff discussions created
# before the introduction of the new implementation still use `LegacyDiffDiscussion`.
#
# A discussion of this type is never resolvable.
class LegacyDiffDiscussion < Discussion
  include DiscussionOnDiff

  memoized_values << :active

  def self.note_class
    LegacyDiffNote
  end

  def legacy_diff_discussion?
    true
  end

  def on_image?
    false
  end

  def on_text?
    true
  end

  def active?(*args)
    return @active if @active.present?

    @active = first_note.active?(*args)
  end

  def collapsed?
    !active?
  end

  def merge_request_version_params
    return unless for_merge_request?

    if active?
      {}
    else
      nil
    end
  end

  def reply_attributes
    super.merge(line_code: line_code)
  end
end
