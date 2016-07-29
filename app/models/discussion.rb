class Discussion
  NUMBER_OF_TRUNCATED_DIFF_LINES = 16

  attr_reader :first_note, :notes

  delegate  :created_at,
            :project,
            :author,

            :noteable,
            :for_commit?,
            :for_merge_request?,

            :line_code,
            :diff_file,
            :for_line?,
            :active?,

            to: :first_note

  delegate :blob, :highlighted_diff_lines, to: :diff_file, allow_nil: true

  def self.for_notes(notes)
    notes.group_by(&:discussion_id).values.map { |notes| new(notes) }
  end

  def self.for_diff_notes(notes)
    notes.group_by(&:line_code).values.map { |notes| new(notes) }
  end

  def initialize(notes)
    @first_note = notes.first
    @notes = notes
  end

  def id
    first_note.discussion_id
  end

  def diff_discussion?
    first_note.diff_note?
  end

  def legacy_diff_discussion?
    notes.any?(&:legacy_diff_note?)
  end

  def for_target?(target)
    self.noteable == target && !diff_discussion?
  end

  def expanded?
    !diff_discussion? || active?
  end

  def reply_attributes
    data = {
      noteable_type: first_note.noteable_type,
      noteable_id:   first_note.noteable_id,
      commit_id:     first_note.commit_id,
      discussion_id: self.id,
    }

    if diff_discussion?
      data[:note_type] = first_note.type

      data.merge!(first_note.diff_attributes)
    end

    data
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
