# frozen_string_literal: true

class Event < ApplicationRecord
  include Sortable
  include FromUnion
  default_scope { reorder(nil) }

  CREATED   = 1
  UPDATED   = 2
  CLOSED    = 3
  REOPENED  = 4
  PUSHED    = 5
  COMMENTED = 6
  MERGED    = 7
  JOINED    = 8 # User joined project
  LEFT      = 9 # User left project
  DESTROYED = 10
  EXPIRED   = 11 # User left project due to expiry

  ACTIONS = HashWithIndifferentAccess.new(
    created:    CREATED,
    updated:    UPDATED,
    closed:     CLOSED,
    reopened:   REOPENED,
    pushed:     PUSHED,
    commented:  COMMENTED,
    merged:     MERGED,
    joined:     JOINED,
    left:       LEFT,
    destroyed:  DESTROYED,
    expired:    EXPIRED
  ).freeze

  TARGET_TYPES = HashWithIndifferentAccess.new(
    issue:          Issue,
    milestone:      Milestone,
    merge_request:  MergeRequest,
    note:           Note,
    project:        Project,
    snippet:        Snippet,
    user:           User
  ).freeze

  RESET_PROJECT_ACTIVITY_INTERVAL = 1.hour
  REPOSITORY_UPDATED_AT_INTERVAL = 5.minutes

  delegate :name, :email, :public_email, :username, to: :author, prefix: true, allow_nil: true
  delegate :title, to: :issue, prefix: true, allow_nil: true
  delegate :title, to: :merge_request, prefix: true, allow_nil: true
  delegate :title, to: :note, prefix: true, allow_nil: true

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
  after_create :track_user_interacted_projects

  # Scopes
  scope :recent, -> { reorder(id: :desc) }
  scope :code_push, -> { where(action: PUSHED) }

  scope :in_projects, -> (projects) do
    sub_query = projects
      .except(:order)
      .select(1)
      .where('projects.id = events.project_id')

    where('EXISTS (?)', sub_query).recent
  end

  scope :with_associations, -> do
    # We're using preload for "push_event_payload" as otherwise the association
    # is not always available (depending on the query being built).
    includes(:author, :project, project: [:project_feature, :import_data, :namespace])
      .preload(:target, :push_event_payload)
  end

  scope :for_milestone_id, ->(milestone_id) { where(target_type: "Milestone", target_id: milestone_id) }

  # Authors are required as they're used to display who pushed data.
  #
  # We're just validating the presence of the ID here as foreign key constraints
  # should ensure the ID points to a valid user.
  validates :author_id, presence: true

  self.inheritance_column = 'action'

  class << self
    def model_name
      ActiveModel::Name.new(self, nil, 'event')
    end

    def find_sti_class(action)
      if action.to_i == PUSHED
        PushEvent
      else
        Event
      end
    end

    # Update Gitlab::ContributionsCalendar#activity_dates if this changes
    def contributions
      where("action = ? OR (target_type IN (?) AND action IN (?)) OR (target_type = ? AND action = ?)",
            Event::PUSHED,
            %w(MergeRequest Issue), [Event::CREATED, Event::CLOSED, Event::MERGED],
            "Note", Event::COMMENTED)
    end

    def limit_recent(limit = 20, offset = nil)
      recent.limit(limit).offset(offset)
    end

    def actions
      ACTIONS.keys
    end

    def target_types
      TARGET_TYPES.keys
    end
  end

  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/PerceivedComplexity
  def visible_to_user?(user = nil)
    if push_action? || commit_note?
      Ability.allowed?(user, :download_code, project)
    elsif membership_changed?
      Ability.allowed?(user, :read_project, project)
    elsif created_project_action?
      Ability.allowed?(user, :read_project, project)
    elsif issue? || issue_note?
      Ability.allowed?(user, :read_issue, note? ? note_target : target)
    elsif merge_request? || merge_request_note?
      Ability.allowed?(user, :read_merge_request, note? ? note_target : target)
    elsif personal_snippet_note?
      Ability.allowed?(user, :read_personal_snippet, note_target)
    elsif project_snippet_note?
      Ability.allowed?(user, :read_project_snippet, note_target)
    elsif milestone?
      Ability.allowed?(user, :read_milestone, project)
    else
      false # No other event types are visible
    end
  end
  # rubocop:enable Metrics/PerceivedComplexity
  # rubocop:enable Metrics/CyclomaticComplexity

  def project_name
    if project
      project.full_name
    else
      "(deleted project)"
    end
  end

  def target_title
    target.try(:title)
  end

  def created_action?
    action == CREATED
  end

  def push_action?
    false
  end

  def merged_action?
    action == MERGED
  end

  def closed_action?
    action == CLOSED
  end

  def reopened_action?
    action == REOPENED
  end

  def joined_action?
    action == JOINED
  end

  def left_action?
    action == LEFT
  end

  def expired_action?
    action == EXPIRED
  end

  def destroyed_action?
    action == DESTROYED
  end

  def commented_action?
    action == COMMENTED
  end

  def membership_changed?
    joined_action? || left_action? || expired_action?
  end

  def created_project_action?
    created_action? && !target && target_type.nil?
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

  def milestone
    target if milestone?
  end

  def issue
    target if issue?
  end

  def merge_request
    target if merge_request?
  end

  def note
    target if note?
  end

  def action_name
    if push_action?
      push_action_name
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
    elsif created_project_action?
      created_project_action_name
    else
      "opened"
    end
  end

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

  def project_snippet_note?
    note? && target && target.for_snippet?
  end

  def personal_snippet_note?
    note? && target && target.for_personal_snippet?
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

  def note_target_type
    if target.noteable_type.present?
      target.noteable_type.titleize
    else
      "Wall"
    end.downcase
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

  private

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

  def track_user_interacted_projects
    # Note the call to .available? is due to earlier migrations
    # that would otherwise conflict with the call to .track
    # (because the table does not exist yet).
    UserInteractedProject.track(self) if UserInteractedProject.available?
  end
end
