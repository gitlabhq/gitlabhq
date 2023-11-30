# frozen_string_literal: true

class Suggestion < ApplicationRecord
  include Importable
  include Suggestible

  belongs_to :note, inverse_of: :suggestions
  validates :note, presence: true, unless: :importing?
  validates :commit_id, presence: true, if: :applied?

  delegate :position, :noteable, to: :note

  scope :active, -> { where(outdated: false) }

  def diff_file
    note.latest_diff_file
  end

  def source_project
    noteable.source_project
  end

  def target_project
    noteable.target_project
  end

  def branch
    noteable.source_branch
  end

  def file_path
    position.file_path
  end

  # `from_line_index` and `to_line_index` represents diff/blob line numbers in
  # index-like way (N-1).
  def from_line_index
    from_line - 1
  end

  def to_line_index
    to_line - 1
  end

  def appliable?(cached: true)
    inapplicable_reason(cached: cached).nil?
  end

  def inapplicable_reason(cached: true)
    strong_memoize("inapplicable_reason_#{cached}") do
      next _("Can't apply this suggestion.") if applied?
      next _("This merge request was merged. To apply this suggestion, edit this file directly.") if noteable.merged?
      next _("This merge request is closed. To apply this suggestion, edit this file directly.") if noteable.closed?
      next _("Can't apply as the source branch was deleted.") unless noteable.source_branch_exists?
      next outdated_reason if outdated?(cached: cached) || !note.active?
      next _("This suggestion already matches its content.") unless different_content?
      next _("This file was modified for readability, and can't accept suggestions. Edit it directly.") if file_path.end_with? "ipynb"
    end
  end

  # Overwrites outdated column
  def outdated?(cached: true)
    return super() if cached
    return true unless diff_file

    from_content != fetch_from_content
  end

  def single_line?
    lines_above == 0 && lines_below == 0
  end

  def target_line
    position.new_line
  end

  private

  def different_content?
    from_content != to_content
  end

  def outdated_reason
    if single_line?
      _("Can't apply as this line was changed in a more recent version.")
    else
      _("Can't apply as these lines were changed in a more recent version.")
    end
  end
end
