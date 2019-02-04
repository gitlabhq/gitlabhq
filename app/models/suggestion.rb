# frozen_string_literal: true

class Suggestion < ApplicationRecord
  belongs_to :note, inverse_of: :suggestions
  validates :note, presence: true
  validates :commit_id, presence: true, if: :applied?

  delegate :original_position, :position, :noteable, to: :note

  def project
    noteable.source_project
  end

  def branch
    noteable.source_branch
  end

  def file_path
    position.file_path
  end

  def diff_file
    repository = project.repository
    position.diff_file(repository)
  end

  # For now, suggestions only serve as a way to send patches that
  # will change a single line (being able to apply multiple in the same place),
  # which explains `from_line` and `to_line` being the same line.
  # We'll iterate on that in https://gitlab.com/gitlab-org/gitlab-ce/issues/53310
  # when allowing multi-line suggestions.
  def from_line
    position.new_line
  end
  alias_method :to_line, :from_line

  def from_original_line
    original_position.new_line
  end
  alias_method :to_original_line, :from_original_line

  # `from_line_index` and `to_line_index` represents diff/blob line numbers in
  # index-like way (N-1).
  def from_line_index
    from_line - 1
  end
  alias_method :to_line_index, :from_line_index

  def appliable?
    return false unless note.supports_suggestion?

    !applied? &&
      noteable.opened? &&
      different_content? &&
      note.active?
  end

  private

  def different_content?
    from_content != to_content
  end
end
