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
    inapplicable_reason(cached: cached).nil?
  end

  def inapplicable_reason(cached: true)
    strong_memoize("inapplicable_reason_#{cached}") do
      next :applied if applied?
      next :merge_request_merged if noteable.merged?
      next :merge_request_closed if noteable.closed?
      next :source_branch_deleted unless noteable.source_branch_exists?
      next :outdated if outdated?(cached: cached) || !note.active?
      next :same_content unless different_content?
    end
  end

  # Overwrites outdated column
  def outdated?(cached: true)
    return super() if cached
    return true unless diff_file

    from_content != fetch_from_content
  end

  def single_line?
    lines_above.zero? && lines_below.zero?
  end

  def target_line
    position.new_line
  end

  private

  def different_content?
    from_content != to_content
  end
end
