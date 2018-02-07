# Contains functionality shared between `DiffDiscussion` and `LegacyDiffDiscussion`.
module DiscussionOnDiff
  extend ActiveSupport::Concern

  NUMBER_OF_TRUNCATED_DIFF_LINES = 16

  included do
    delegate  :line_code,
              :original_line_code,
              :diff_file,
              :diff_line,
              :active?,
              :created_at_diff?,

              to: :first_note

    delegate  :file_path,
              :blob,
              :highlighted_diff_lines,
              :diff_lines,

              to: :diff_file,
              allow_nil: true
  end

  def diff_discussion?
    true
  end

  def file_new_path
    first_note.position.new_path
  end

  def on_merge_request_commit?
    for_merge_request? && commit_id.present?
  end

  # Returns an array of at most 16 highlighted lines above a diff note
  def truncated_diff_lines(highlight: true)
    return [] if diff_line.nil? && first_note.is_a?(LegacyDiffNote)

    lines = highlight ? highlighted_diff_lines : diff_lines

    initial_line_index = [diff_line.index - NUMBER_OF_TRUNCATED_DIFF_LINES + 1, 0].max

    prev_lines = []

    lines[initial_line_index..diff_line.index].each do |line|
      if line.meta?
        prev_lines.clear
      else
        prev_lines << line
      end
    end

    prev_lines
  end

  def line_code_in_diffs(diff_refs)
    if active?(diff_refs)
      line_code
    elsif diff_refs && created_at_diff?(diff_refs)
      original_line_code
    end
  end
end
