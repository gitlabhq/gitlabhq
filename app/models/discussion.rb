class Discussion
  NUMBER_OF_TRUNCATED_DIFF_LINES = 16

  attr_reader :notes

  delegate  :created_at,
            :project,
            :author,

            :noteable,
            :for_commit?,
            :for_merge_request?,

            :line_code,
            :original_line_code,
            :diff_file,
            :for_line?,
            :active?,

            to: :first_note

  delegate  :resolved_at,
            :resolved_by,

            to: :last_resolved_note,
            allow_nil: true

  delegate :blob, :highlighted_diff_lines, to: :diff_file, allow_nil: true

  def self.for_notes(notes)
    notes.group_by(&:discussion_id).values.map { |notes| new(notes) }
  end

  def self.for_diff_notes(notes)
    notes.group_by(&:line_code).values.map { |notes| new(notes) }
  end

  def initialize(notes)
    @notes = notes
  end

  def last_resolved_note
    return unless resolved?

    @last_resolved_note ||= resolved_notes.sort_by(&:resolved_at).last
  end

  def last_updated_at
    last_note.created_at
  end

  def last_updated_by
    last_note.author
  end

  def id
    first_note.discussion_id
  end

  alias_method :to_param, :id

  def diff_discussion?
    first_note.diff_note?
  end

  def legacy_diff_discussion?
    notes.any?(&:legacy_diff_note?)
  end

  def resolvable?
    return @resolvable if @resolvable.present?

    @resolvable = diff_discussion? && notes.any?(&:resolvable?)
  end

  def resolved?
    return @resolved if @resolved.present?

    @resolved = resolvable? && notes.none?(&:to_be_resolved?)
  end

  def first_note
    @first_note ||= @notes.first
  end

  def last_note
    @last_note ||= @notes.last
  end

  def resolved_notes
    notes.select(&:resolved?)
  end

  def to_be_resolved?
    resolvable? && !resolved?
  end

  def can_resolve?(current_user)
    return false unless current_user
    return false unless resolvable?

    current_user == self.noteable.author ||
      current_user.can?(:resolve_note, self.project)
  end

  def resolve!(current_user)
    return unless resolvable?

    update { |notes| notes.resolve!(current_user) }
  end

  def unresolve!
    return unless resolvable?

    update { |notes| notes.unresolve! }
  end

  def for_target?(target)
    self.noteable == target && !diff_discussion?
  end

  def active?
    return @active if @active.present?

    @active = first_note.active?
  end

  def collapsed?
    return false unless diff_discussion?

    if resolvable?
      # New diff discussions only disappear once they are marked resolved
      resolved?
    else
      # Old diff discussions disappear once they become outdated
      !active?
    end
  end

  def expanded?
    !collapsed?
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

  private

  def update
    notes_relation = DiffNote.where(id: notes.map(&:id)).fresh
    yield(notes_relation)

    # Set the notes array to the updated notes
    @notes = notes_relation.to_a

    # Reset the memoized values
    @last_resolved_note = @resolvable = @resolved = @first_note = @last_note = nil
  end
end
