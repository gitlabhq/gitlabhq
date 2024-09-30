# frozen_string_literal: true

module Noteable
  extend ActiveSupport::Concern

  # This object is used to gather noteable meta data for list displays
  # avoiding n+1 queries and improving performance.
  NoteableMeta = Struct.new(:user_notes_count)

  MAX_NOTES_LIMIT = 5_000

  class_methods do
    # `Noteable` class names that support replying to individual notes.
    def replyable_types
      %w[Issue MergeRequest AbuseReport WikiPage::Meta]
    end

    # `Noteable` class names that support resolvable notes.
    def resolvable_types
      %w[Issue MergeRequest DesignManagement::Design AbuseReport WikiPage::Meta]
    end

    # `Noteable` class names that support creating/forwarding individual notes.
    def email_creatable_types
      %w[Issue]
    end
  end

  # The timestamp of the note (e.g. the :created_at or :updated_at attribute if provided via
  # API call)
  def system_note_timestamp
    @system_note_timestamp || Time.current # rubocop:disable Gitlab/ModuleWithInstanceVariables
  end

  attr_writer :system_note_timestamp

  def base_class_name
    self.class.base_class.name
  end

  # Convert this Noteable class name to a format usable by notifications.
  #
  # Examples:
  #
  #   noteable.class           # => MergeRequest
  #   noteable.human_class_name # => "merge request"
  def human_class_name
    @human_class_name ||= base_class_name.titleize.downcase
  end

  def supports_resolvable_notes?
    self.class.resolvable_types.include?(base_class_name)
  end

  def supports_discussions?
    DiscussionNote.noteable_types.include?(base_class_name)
  end

  def supports_replying_to_individual_notes?
    supports_discussions? && self.class.replyable_types.include?(base_class_name)
  end

  def supports_creating_notes_by_email?
    self.class.email_creatable_types.include?(base_class_name)
  end

  def supports_suggestion?
    false
  end

  def discussions_rendered_on_frontend?
    false
  end

  def preloads_discussion_diff_highlighting?
    false
  end

  def has_any_diff_note_positions?
    notes.any? && DiffNotePosition.where(note: notes).exists?
  end

  def discussion_notes
    notes
  end

  delegate :find_discussion, to: :discussion_notes

  def discussions
    @discussions ||= discussion_notes
      .inc_relations_for_view(self)
      .discussions(self)
  end

  def discussion_ids_relation
    notes.select(:discussion_id)
      .group(:discussion_id)
      .order('MIN(created_at), MIN(id)')
  end

  # This does not consider OutOfContextDiscussions in MRs
  # where notes from commits are overriden so that they have
  # the same discussion_id
  def discussion_root_note_ids(notes_filter:)
    relations = []

    relations << discussion_notes.select(
      "'notes' AS table_name",
      'MIN(id) AS id',
      'MIN(created_at) AS created_at',
      'ARRAY_AGG(id) AS ids'
    ).with_notes_filter(notes_filter)
     .group(:discussion_id)

    if notes_filter != UserPreference::NOTES_FILTERS[:only_comments]
      relations += synthetic_note_ids_relations
    end

    Note.from_union(relations, remove_duplicates: false)
      .select(:table_name, :id, :created_at, :ids)
      .fresh
  end

  def capped_notes_count(max)
    notes.limit(max).count
  end

  def grouped_diff_discussions(...)
    # Doesn't use `discussion_notes`, because this may include commit diff notes
    # besides MR diff notes, that we do not want to display on the MR Changes tab.
    notes.inc_relations_for_view(self).grouped_diff_discussions(...)
  end

  # rubocop:disable Gitlab/ModuleWithInstanceVariables
  def resolvable_discussions
    @resolvable_discussions ||=
      if defined?(@discussions)
        @discussions.select(&:resolvable?)
      else
        discussion_notes.resolvable.discussions(self)
      end
  end
  # rubocop:enable Gitlab/ModuleWithInstanceVariables

  def discussions_resolvable?
    resolvable_discussions.any?(&:resolvable?)
  end

  def discussions_resolved?
    discussions_resolvable? && resolvable_discussions.none?(&:to_be_resolved?)
  end

  def discussions_to_be_resolved
    @discussions_to_be_resolved ||= resolvable_discussions.select(&:to_be_resolved?)
  end

  def discussions_can_be_resolved_by?(user)
    discussions_to_be_resolved.all? { |discussion| discussion.can_resolve?(user) }
  end

  def lockable?
    [MergeRequest, Issue].include?(self.class)
  end

  def real_time_notes_enabled?
    false
  end

  def broadcast_notes_changed
    return unless discussions_rendered_on_frontend?
    return unless real_time_notes_enabled?

    Noteable::NotesChannel.broadcast_to(self, event: 'updated')
  end

  def after_note_created(_note)
    # no-op
  end

  def after_note_destroyed(_note)
    # no-op
  end

  # Email address that an authorized user can send/forward an email to be added directly
  # to an issue or merge request.
  # example: incoming+h5bp-html5-boilerplate-8-1234567890abcdef123456789-issue-34@localhost.com
  def creatable_note_email_address(author)
    return unless supports_creating_notes_by_email?

    project_email = project&.new_issuable_address(author, base_class_name.underscore)
    return unless project_email

    project_email.sub('@', "-#{iid}@")
  end

  def noteable_target_type_name
    model_name.singular
  end

  def commenters(user: nil)
    eligable_notes = notes.user

    eligable_notes = eligable_notes.not_internal unless user&.can?(:read_internal_note, self)

    User.where(id: eligable_notes.select(:author_id).distinct)
  end

  private

  # Synthetic system notes don't have discussion IDs because these are generated dynamically
  # in Ruby. These are always root notes anyway so we don't need to group by discussion ID.
  def synthetic_note_ids_relations
    relations = []

    # currently multiple models include Noteable concern, but not all of them support
    # all resource events, so we check if given model supports given resource event.
    if respond_to?(:resource_label_events)
      relations << resource_label_events.select("'resource_label_events'", 'MIN(id)', :created_at, 'ARRAY_AGG(id)')
                     .group(:created_at, :user_id)
    end

    if respond_to?(:resource_state_events)
      relations << resource_state_events.select("'resource_state_events'", :id, :created_at, 'ARRAY_FILL(id, ARRAY[1])')
    end

    if respond_to?(:resource_milestone_events)
      relations << resource_milestone_events.select("'resource_milestone_events'", :id, :created_at, 'ARRAY_FILL(id, ARRAY[1])')
    end

    relations
  end
end

Noteable.extend(Noteable::ClassMethods)

Noteable::ClassMethods.prepend_mod_with('Noteable::ClassMethods')
Noteable.prepend_mod_with('Noteable')
