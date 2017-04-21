# Contains functionality shared between `DiffNote` and `LegacyDiffNote`.
module NoteOnDiff
  extend ActiveSupport::Concern

  def diff_note?
    true
  end

  def diff_file
    raise NotImplementedError
  end

  def diff_line
    raise NotImplementedError
  end

  def for_line?(line)
    raise NotImplementedError
  end

  def original_line_code
    raise NotImplementedError
  end

  def diff_attributes
    raise NotImplementedError
  end

  def active?(diff_refs = nil)
    raise NotImplementedError
  end

  private

  def noteable_diff_refs
    if noteable.respond_to?(:diff_sha_refs)
      noteable.diff_sha_refs
    else
      noteable.diff_refs
    end
  end
end
