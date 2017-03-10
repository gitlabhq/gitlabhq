class DiffDiscussion < Discussion
  NUMBER_OF_TRUNCATED_DIFF_LINES = 16

  delegate  :line_code,
            :original_line_code,
            :diff_file,
            :for_line?,
            :active?,

            to: :first_note

  delegate  :blob,
            :highlighted_diff_lines,
            :diff_lines,

            to: :diff_file,
            allow_nil: true

  def self.build_discussion_id(note)
    [*super(note), *unique_position_identifier(note)]
  end

  def self.build_original_discussion_id(note)
    [*Discussion.build_discussion_id(note), *note.original_position.key]
  end

  def self.unique_position_identifier(note)
    note.position.key
  end

  def diff_discussion?
    true
  end

  def legacy_diff_discussion?
    false
  end

  def active?
    return @active if @active.present?

    @active = first_note.active?
  end
  MEMOIZED_VALUES << :active

  def reply_attributes
    super.merge(first_note.diff_attributes)
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
