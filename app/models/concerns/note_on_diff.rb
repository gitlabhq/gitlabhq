# frozen_string_literal: true

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

  def original_line_code
    raise NotImplementedError
  end

  def diff_attributes
    raise NotImplementedError
  end

  def active?(diff_refs = nil)
    raise NotImplementedError
  end

  def created_at_diff?(diff_refs)
    false
  end
end
