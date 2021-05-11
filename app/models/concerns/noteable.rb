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
      %w(Issue MergeRequest)
    end

    # `Noteable` class names that support resolvable notes.
    def resolvable_types
      %w(MergeRequest DesignManagement::Design)
    end

    # `Noteable` class names that support creating/forwarding individual notes.
    def email_creatable_types
      %w(Issue)
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
      .inc_relations_for_view
      .discussions(self)
  end

  def discussion_ids_relation
    notes.select(:discussion_id)
      .group(:discussion_id)
      .order('MIN(created_at), MIN(id)')
  end

  def capped_notes_count(max)
    notes.limit(max).count
  end

  def grouped_diff_discussions(*args)
    # Doesn't use `discussion_notes`, because this may include commit diff notes
    # besides MR diff notes, that we do not want to display on the MR Changes tab.
    notes.inc_relations_for_view.grouped_diff_discussions(*args)
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

  def etag_caching_enabled?
    false
  end

  def expire_note_etag_cache
    return unless discussions_rendered_on_frontend?
    return unless etag_caching_enabled?

    Gitlab::EtagCaching::Store.new.touch(note_etag_key)
  end

  def note_etag_key
    return Gitlab::Routing.url_helpers.designs_project_issue_path(project, issue, { vueroute: filename }) if self.is_a?(DesignManagement::Design)

    Gitlab::Routing.url_helpers.project_noteable_notes_path(
      project,
      target_type: self.class.name.underscore,
      target_id: id
    )
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

    project_email = project.new_issuable_address(author, self.class.name.underscore)
    return unless project_email

    project_email.sub('@', "-#{iid}@")
  end
end

Noteable.extend(Noteable::ClassMethods)

Noteable::ClassMethods.prepend_mod_with('Noteable::ClassMethods')
Noteable.prepend_mod_with('Noteable')
