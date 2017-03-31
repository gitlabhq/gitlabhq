class Discussion
  cattr_accessor :memoized_values, instance_accessor: false do
    []
  end

  include ResolvableDiscussion

  attr_reader :notes, :noteable

  delegate  :created_at,
            :project,
            :author,

            :noteable,
            :for_commit?,
            :for_merge_request?,

            to: :first_note

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

  def last_note
    @last_note ||= notes.last
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

    self.class.memoized_values.each do |var|
      instance_variable_set(:"@#{var}", nil)
    end
  end
end
