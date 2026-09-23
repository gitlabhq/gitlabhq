# frozen_string_literal: true

class Suggestion < ApplicationRecord
  include Importable
  include Suggestible
  include Notes::WithAssociatedNote

  belongs_to :note, inverse_of: :suggestions
  belongs_to :namespace

  validates :note, presence: true, unless: :importing?
  validates :commit_id, presence: true, if: :applied?

  delegate :position, :noteable, to: :note

  scope :active, -> { where(outdated: false) }

  def diff_file
    note.latest_diff_file
  end

  # `latest_diff_file` runs a Gitaly compare on every discussions load; the
  # discussion diff file comes from the stored `note_diff_files` row and is
  # enough to pick a lexer. Replies share the first note position but never
  # get a row of their own, so they borrow it from the discussion.
  def diff_file_for_highlight
    return diff_file unless Feature.enabled?(:suggestion_highlight_uses_note_diff_file, note.project)

    note.discussion.diff_file
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
      next oversized_reason if oversized?
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

  def oversized_reason
    format(
      _("Cannot apply as this suggestion spans more than %{max_lines} lines."),
      max_lines: Suggestible::MAX_LINES_CONTEXT
    )
  end

  def outdated_reason
    if single_line?
      _("Can't apply as this line was changed in a more recent version.")
    else
      _("Can't apply as these lines were changed in a more recent version.")
    end
  end

  def skip_namespace_validation?
    importing?
  end

  def note_namespace_id
    note&.namespace_id || note&.project&.project_namespace_id
  end
end
