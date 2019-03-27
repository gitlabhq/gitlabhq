# frozen_string_literal: true

class Suggestion < ApplicationRecord
  include Suggestible

  belongs_to :note, inverse_of: :suggestions
  validates :note, presence: true
  validates :commit_id, presence: true, if: :applied?

  delegate :position, :noteable, to: :note

  scope :active, -> { where(outdated: false) }

  def diff_file
    note.latest_diff_file
  end

  def project
    noteable.source_project
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
    !applied? &&
      noteable.opened? &&
      !outdated?(cached: cached) &&
      note.supports_suggestion? &&
      different_content? &&
      note.active?
  end

  # Overwrites outdated column
  def outdated?(cached: true)
    return super() if cached
    return true unless diff_file

    from_content != fetch_from_content
  end

  def target_line
    position.new_line
  end

  private

  def different_content?
    from_content != to_content
  end
end
