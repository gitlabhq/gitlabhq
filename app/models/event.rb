# frozen_string_literal: true

class Event < ApplicationRecord
  include Sortable
  include FromUnion
  include Presentable
  include DeleteWithLimit
  include CreatedAtFilterable
  include Gitlab::Utils::StrongMemoize
  include UsageStatistics
  include ShaAttribute

  default_scope { reorder(nil) } # rubocop:disable Cop/DefaultScope

  ACTIONS = HashWithIndifferentAccess.new(
    created:    1,
    updated:    2,
    closed:     3,
    reopened:   4,
    pushed:     5,
    commented:  6,
    merged:     7,
    joined:     8, # User joined project
    left:       9, # User left project
    destroyed:  10,
    expired:    11, # User left project due to expiry
    approved:   12
  ).freeze

  private_constant :ACTIONS

  WIKI_ACTIONS = [:created, :updated, :destroyed].freeze

  DESIGN_ACTIONS = [:created, :updated, :destroyed].freeze

  TARGET_TYPES = HashWithIndifferentAccess.new(
    issue:          Issue,
    milestone:      Milestone,
    merge_request:  MergeRequest,
    note:           Note,
    project:        Project,
    snippet:        Snippet,
    user:           User,
    wiki:           WikiPage::Meta,
    design:         DesignManagement::Design
  ).freeze

  RESET_PROJECT_ACTIVITY_INTERVAL = 1.hour
  REPOSITORY_UPDATED_AT_INTERVAL = 5.minutes

  sha_attribute :fingerprint

  enum action: ACTIONS, _suffix: true

  delegate :name, :email, :public_email, :username, to: :author, prefix: true, allow_nil: true
  delegate :title, to: :issue, prefix: true, allow_nil: true
  delegate :title, to: :merge_request, prefix: true, allow_nil: true
  delegate :title, to: :note, prefix: true, allow_nil: true
  delegate :title, to: :design, prefix: true, allow_nil: true

  belongs_to :author, class_name: "User"
  belongs_to :project
  belongs_to :group

  belongs_to :target, -> {
    # If the association for "target" defines an "author" association we want to
    # eager-load this so Banzai & friends don't end up performing N+1 queries to
    # get the authors of notes, issues, etc. (likewise for "noteable").
    incs = %i(author noteable).select do |a|
      reflections['events'].active_record.reflect_on_association(a)
    end

    incs.reduce(self) { |obj, a| obj.includes(a) }
  }, polymorphic: true # rubocop:disable Cop/PolymorphicAssociations

  has_one :push_event_payload

  # Callbacks
  after_create :reset_project_activity
  after_create :set_last_repository_updated_at, if: :push_action?
  after_create ->(event) { UserInteractedProject.track(event) }

  # Scopes
  scope :recent, -> { reorder(id: :desc) }
  scope :for_wiki_page, -> { where(target_type: 'WikiPage::Meta') }
  scope :for_design, -> { where(target_type: 'DesignManagement::Design') }
  scope :for_fingerprint, ->(fingerprint) do
    fingerprint.present? ? where(fingerprint: fingerprint) : none
  end
  scope :for_action, ->(action) { where(action: action) }

  scope :with_associations, -> do
    # We're using preload for "push_event_payload" as otherwise the association
    # is not always available (depending on the query being built).
    includes(:author, :project, project: [:project_feature, :import_data, :namespace])
      .preload(:target, :push_event_payload)
  end

  scope :for_milestone_id, ->(milestone_id) { where(target_type: "Milestone", target_id: milestone_id) }
  scope :for_wiki_meta, ->(meta) { where(target_type: 'WikiPage::Meta', target_id: meta.id) }
  scope :created_at, ->(time) { where(created_at: time) }

  # Authors are required as they're used to display who pushed data.
  #
  # We're just validating the presence of the ID here as foreign key constraints
  # should ensure the ID points to a valid user.
  validates :author_id, presence: true

  validates :action_enum_value,
    if: :design?,
    inclusion: {
      in: actions.values_at(*DESIGN_ACTIONS),
      message: ->(event, _data) { "#{event.action} is not a valid design action" }
    }

  self.inheritance_column = 'action'

  class << self
    def model_name
      ActiveModel::Name.new(self, nil, 'event')
    end

    def find_sti_class(action)
      if actions.fetch(action, action) == actions[:pushed] # action can be integer or symbol
        PushEvent
      else
        Event
      end
    end

    # Update Gitlab::ContributionsCalendar#activity_dates if this changes
    def contributions
      where("action = ? OR (target_type IN (?) AND action IN (?)) OR (target_type = ? AND action = ?)",
            actions[:pushed],
            %w(MergeRequest Issue), [actions[:created], actions[:closed], actions[:merged]],
            "Note", actions[:commented])
    end

    def limit_recent(limit = 20, offset = nil)
      recent.limit(limit).offset(offset)
    end

    def target_types
      TARGET_TYPES.keys
    end
  end

  def present
    super(presenter_class: ::EventPresenter)
  end

  def visible_to_user?(user = nil)
    return false unless capability.present?

    capability.all? do |rule|
      Ability.allowed?(user, rule, permission_object)
    end
  end

  def resource_parent
    project || group
  end

  def target_title
    target.try(:title)
  end

  def push_action?
    false
  end

  def membership_changed?
    joined_action? || left_action? || expired_action?
  end

  def created_project_action?
    created_action? && !target && target_type.nil?
  end

  def created_wiki_page?
    wiki_page? && created_action?
  end

  def updated_wiki_page?
    wiki_page? && updated_action?
  end

  def created_target?
    created_action? && target
  end

  def milestone?
    target_type == "Milestone"
  end

  def note?
    target.is_a?(Note)
  end

  def issue?
    target_type == "Issue"
  end

  def merge_request?
    target_type == "MergeRequest"
  end

  def wiki_page?
    target_type == 'WikiPage::Meta'
  end

  def design?
    target_type == 'DesignManagement::Design'
  end

  def milestone
    target if milestone?
  end

  def issue
    target if issue?
  end

  def design
    target if design?
  end

  def merge_request
    target if merge_request?
  end

  def wiki_page
    strong_memoize(:wiki_page) do
      next unless wiki_page?

      ProjectWiki.new(project, author).find_page(target.canonical_slug)
    end
  end

  def note
    target if note?
  end

  # rubocop: disable Metrics/CyclomaticComplexity
  # rubocop: disable Metrics/PerceivedComplexity
  def action_name
    if push_action?
      push_action_name
    elsif design?
      design_action_names[action.to_sym]
    elsif closed_action?
      "closed"
    elsif merged_action?
      "accepted"
    elsif joined_action?
      'joined'
    elsif left_action?
      'left'
    elsif expired_action?
      'removed due to membership expiration from'
    elsif destroyed_action?
      'destroyed'
    elsif commented_action?
      "commented on"
    elsif created_wiki_page?
      'created'
    elsif updated_wiki_page?
      'updated'
    elsif created_project_action?
      created_project_action_name
    elsif approved_action?
      'approved'
    else
      "opened"
    end
  end
  # rubocop: enable Metrics/CyclomaticComplexity
  # rubocop: enable Metrics/PerceivedComplexity

  def target_iid
    target.respond_to?(:iid) ? target.iid : target_id
  end

  def commit_note?
    note? && target && target.for_commit?
  end

  def issue_note?
    note? && target && target.for_issue?
  end

  def merge_request_note?
    note? && target && target.for_merge_request?
  end

  def snippet_note?
    note? && target && target.for_snippet?
  end

  def project_snippet_note?
    note? && target && target.for_project_snippet?
  end

  def personal_snippet_note?
    note? && target && target.for_personal_snippet?
  end

  def design_note?
    note? && note.for_design?
  end

  def note_target
    target.noteable
  end

  def note_target_id
    if commit_note?
      target.commit_id
    else
      target.noteable_id.to_s
    end
  end

  def note_target_reference
    return unless note_target

    # Commit#to_reference returns the full SHA, but we want the short one here
    if commit_note?
      note_target.short_id
    else
      note_target.to_reference
    end
  end

  def body?
    if push_action?
      push_with_commits?
    elsif note?
      true
    else
      target.respond_to? :title
    end
  end

  def reset_project_activity
    return unless project

    # Don't bother updating if we know the project was updated recently.
    return if recent_update?

    # At this point it's possible for multiple threads/processes to try to
    # update the project. Only one query should actually perform the update,
    # hence we add the extra WHERE clause for last_activity_at.
    Project.unscoped.where(id: project_id)
      .where('last_activity_at <= ?', RESET_PROJECT_ACTIVITY_INTERVAL.ago)
      .update_all(last_activity_at: created_at)
  end

  def authored_by?(user)
    user ? author_id == user.id : false
  end

  def to_partial_path
    # We are intentionally using `Event` rather than `self.class` so that
    # subclasses also use the `Event` implementation.
    Event._to_partial_path
  end

  protected

  def capability
    @capability ||= begin
      capabilities.flat_map do |ability, syms|
        if syms.any? { |sym| send(sym) } # rubocop: disable GitlabSecurity/PublicSend
          [ability]
        else
          []
        end
      end
    end
  end

  def capabilities
    {
      download_code: %i[push_action? commit_note?],
      read_project: %i[membership_changed? created_project_action?],
      read_issue: %i[issue? issue_note?],
      read_merge_request: %i[merge_request? merge_request_note?],
      read_snippet: %i[personal_snippet_note? project_snippet_note?],
      read_milestone: %i[milestone?],
      read_wiki: %i[wiki_page?],
      read_design: %i[design_note? design?],
      read_note: %i[note?]
    }
  end

  private

  def permission_object
    if target_id.present?
      target
    else
      project
    end
  end

  def push_action_name
    if new_ref?
      "pushed new"
    elsif rm_ref?
      "deleted"
    else
      "pushed to"
    end
  end

  def created_project_action_name
    if project.external_import?
      "imported"
    else
      "created"
    end
  end

  def recent_update?
    project.last_activity_at > RESET_PROJECT_ACTIVITY_INTERVAL.ago
  end

  def set_last_repository_updated_at
    Project.unscoped.where(id: project_id)
      .where("last_repository_updated_at < ? OR last_repository_updated_at IS NULL", REPOSITORY_UPDATED_AT_INTERVAL.ago)
      .update_all(last_repository_updated_at: created_at)
  end

  def design_action_names
    {
      created: _('uploaded'),
      updated: _('revised'),
      destroyed: _('deleted')
    }
  end

  def action_enum_value
    self.class.actions[action]
  end
end

Event.prepend_mod_with('Event')
