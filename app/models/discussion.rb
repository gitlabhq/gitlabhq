class Discussion
  MEMOIZED_VALUES = [] # rubocop:disable Style/MutableConstant

  attr_reader :notes, :noteable

  delegate  :created_at,
            :project,
            :author,

            :noteable,
            :for_commit?,
            :for_merge_request?,

            to: :first_note

  delegate  :resolved_at,
            :resolved_by,

            to: :last_resolved_note,
            allow_nil: true

  def self.build(notes, noteable = nil)
    notes.first.discussion_class(noteable).new(notes, noteable)
  end

  def self.build_collection(notes, noteable = nil)
    notes.group_by { |n| n.discussion_id(noteable) }.values.map { |notes| build(notes, noteable) }
  end

  def self.discussion_id(note)
    Digest::SHA1.hexdigest(build_discussion_id(note).join("-"))
  end

  # Optionally override the discussion ID at runtime depending on circumstances
  def self.override_discussion_id(note)
    nil
  end

  def self.build_discussion_id(note)
    noteable_id = note.noteable_id || note.commit_id
    [:discussion, note.noteable_type.try(:underscore), noteable_id]
  end

  def self.original_discussion_id(note)
    original_discussion_id = build_original_discussion_id(note)
    if original_discussion_id
      Digest::SHA1.hexdigest(original_discussion_id.join("-"))
    else
      note.discussion_id
    end
  end

  # Optionally build a separate original discussion ID that will never change,
  # if the main discussion ID _can_ change, like in the case of DiffDiscussion.
  def self.build_original_discussion_id(note)
    nil
  end

  def initialize(notes, noteable = nil)
    @notes = notes
    @noteable = noteable
  end

  def ==(other)
    other.class == self.class &&
      other.noteable == self.noteable &&
      other.id == self.id &&
      other.notes == self.notes
  end

  def last_updated_at
    last_note.created_at
  end

  def last_updated_by
    last_note.author
  end

  def id
    first_note.discussion_id(noteable)
  end

  alias_method :to_param, :id

  def original_id
    first_note.original_discussion_id
  end

  def diff_discussion?
    false
  end

  def individual_note?
    false
  end

  def new_discussion?
    notes.length == 1
  end

  # Keep this method in sync with the `potentially_resolvable` scope on `ResolvableNote`
  def potentially_resolvable?
    for_merge_request?
  end

  def resolvable?
    return @resolvable if @resolvable.present?

    @resolvable = potentially_resolvable? && notes.any?(&:resolvable?)
  end
  MEMOIZED_VALUES << :resolvable

  def resolved?
    return @resolved if @resolved.present?

    @resolved = resolvable? && notes.none?(&:to_be_resolved?)
  end
  MEMOIZED_VALUES << :resolved

  def first_note
    @first_note ||= notes.first
  end
  MEMOIZED_VALUES << :first_note

  def first_note_to_resolve
    return unless resolvable?

    @first_note_to_resolve ||= notes.find(&:to_be_resolved?)
  end
  MEMOIZED_VALUES << :first_note_to_resolve

  def last_resolved_note
    return unless resolved?

    @last_resolved_note ||= resolved_notes.sort_by(&:resolved_at).last
  end
  MEMOIZED_VALUES << :last_resolved_note

  def last_note
    @last_note ||= notes.last
  end
  MEMOIZED_VALUES << :last_note

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

  def collapsed?
    resolved?
  end

  def expanded?
    !collapsed?
  end

  def reply_attributes
    first_note.slice(:type, :noteable_type, :noteable_id, :commit_id)
  end

  private

  def update
    # Do not select `Note.resolvable`, so that system notes remain in the collection
    notes_relation = Note.where(id: notes.map(&:id))

    yield(notes_relation)

    # Set the notes array to the updated notes
    @notes = notes_relation.fresh.to_a

    MEMOIZED_VALUES.each do |var|
      instance_variable_set(:"@#{var}", nil)
    end
  end
end
