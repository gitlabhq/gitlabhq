# frozen_string_literal: true

# A non-diff discussion on an issue, merge request, commit, or snippet, consisting of `DiscussionNote` notes.
#
# A discussion of this type can be resolvable.
class Discussion
  include GlobalID::Identification
  include ResolvableDiscussion

  attr_reader :notes, :context_noteable

  delegate  :created_at,
            :project,
            :author,
            :noteable,
            :commit_id,
            :for_commit?,
            :for_merge_request?,
            :noteable_ability_name,
            :to_ability_name,
            :editable?,
            :visible_for?,

            to: :first_note

  def declarative_policy_delegate
    first_note
  end

  def project_id
    project&.id
  end

  def self.build(notes, context_noteable = nil)
    notes.first.discussion_class(context_noteable).new(notes, context_noteable)
  end

  def self.build_collection(notes, context_noteable = nil)
    grouped_notes = notes.group_by { |n| n.discussion_id(context_noteable) }
    grouped_notes.values.map { |notes| build(notes, context_noteable) }
  end

  def self.lazy_find(discussion_id)
    BatchLoader.for(discussion_id).batch do |discussion_ids, loader|
      results = Note.where(discussion_id: discussion_ids).fresh.to_a.group_by(&:discussion_id)
      results.each do |discussion_id, notes|
        next if notes.empty?

        loader.call(discussion_id, Discussion.build(notes))
      end
    end
  end

  # Returns an alphanumeric discussion ID based on `build_discussion_id`
  def self.discussion_id(note)
    Digest::SHA1.hexdigest(build_discussion_id(note).join("-"))
  end

  # Returns an array of discussion ID components
  def self.build_discussion_id(note)
    [*base_discussion_id(note), SecureRandom.hex]
  end

  def self.base_discussion_id(note)
    noteable_id = note.noteable_id || note.commit_id
    [:discussion, note.noteable_type.try(:underscore), noteable_id]
  end

  # When notes on a commit are displayed in context of a merge request that contains that commit,
  # these notes are to be displayed as if they were part of one discussion, even though they were actually
  # individual notes on the commit with different discussion IDs, so that it's clear that these are not
  # notes on the merge request itself.
  #
  # To turn a list of notes into a list of discussions, they are grouped by discussion ID, so to
  # get these out-of-context notes to end up in the same discussion, we need to get them to return the same
  # `discussion_id` when this grouping happens. To enable this, `Note#discussion_id` calls out
  # to the `override_discussion_id` method on the appropriate `Discussion` subclass, as determined by
  # the `discussion_class` method on `Note` or a subclass of `Note`.
  #
  # If no override is necessary, return `nil`.
  # For the case described above, see `OutOfContextDiscussion.override_discussion_id`.
  def self.override_discussion_id(note)
    nil
  end

  def self.note_class
    DiscussionNote
  end

  def initialize(notes, context_noteable = nil)
    @notes = notes
    @context_noteable = context_noteable
  end

  def on_image?
    false
  end

  def ==(other)
    other.class == self.class &&
      other.context_noteable == self.context_noteable &&
      other.id == self.id &&
      other.notes == self.notes
  end

  def last_updated_at
    last_note.created_at
  end

  def last_updated_by
    last_note.author
  end

  def updated?
    last_updated_at != created_at
  end

  def id
    first_note.discussion_id(context_noteable)
  end

  def reply_id
    # To reply to this discussion, we need the actual discussion_id from the database,
    # not the potentially overwritten one based on the noteable.
    first_note.discussion_id
  end

  alias_method :to_param, :id

  def diff_discussion?
    false
  end

  def individual_note?
    false
  end

  def can_convert_to_discussion?
    false
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
    first_note.slice(:type, :noteable_type, :noteable_id, :commit_id, :discussion_id)
  end
end
