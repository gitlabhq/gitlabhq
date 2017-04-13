# Contains functionality shared between `DiffDiscussion` and `LegacyDiffDiscussion`.
module DiscussionOnDiff
  extend ActiveSupport::Concern

<<<<<<< HEAD
  included do
    NUMBER_OF_TRUNCATED_DIFF_LINES = 16

=======
  NUMBER_OF_TRUNCATED_DIFF_LINES = 16

  included do
>>>>>>> ce/master
    delegate  :line_code,
              :original_line_code,
              :diff_file,
              :diff_line,
              :for_line?,
              :active?,

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

  # Returns an array of at most 16 highlighted lines above a diff note
  def truncated_diff_lines(highlight: true)
    lines = highlight ? highlighted_diff_lines : diff_lines
    prev_lines = []

    lines.each do |line|
      if line.meta?
        prev_lines.clear
      else
        prev_lines << line

        break if for_line?(line)

        prev_lines.shift if prev_lines.length >= NUMBER_OF_TRUNCATED_DIFF_LINES
      end
    end

    prev_lines
  end
end
