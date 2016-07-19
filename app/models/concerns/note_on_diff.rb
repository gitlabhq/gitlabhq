module NoteOnDiff
  extend ActiveSupport::Concern

  NUMBER_OF_TRUNCATED_DIFF_LINES = 16

  included do
    delegate :blob, :highlighted_diff_lines, to: :diff_file, allow_nil: true
  end

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

  def diff_attributes
    raise NotImplementedError
  end

  def can_be_award_emoji?
    false
  end

  # Returns an array of at most 16 highlighted lines above a diff note
  def truncated_diff_lines
    prev_lines = []

    highlighted_diff_lines.each do |line|
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
