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
  include EachBatch
  include Import::HasImportSource

  ACTIONS = HashWithIndifferentAccess.new(
    created: 1,
    updated: 2,
    closed: 3,
    reopened: 4,
    pushed: 5,
    commented: 6,
    merged: 7,
    joined: 8, # User joined project
    left: 9, # User left project
    destroyed: 10,
    expired: 11, # User left project due to expiry
    approved: 12
  ).freeze

  private_constant :ACTIONS

  WIKI_ACTIONS = [:created, :updated, :destroyed].freeze
  DESIGN_ACTIONS = [:created, :updated, :destroyed].freeze
  TEAM_ACTIONS = [:joined, :left, :expired].freeze
  ISSUE_ACTIONS = [:created, :updated, :closed, :reopened].freeze
  ISSUE_TYPES = [Issue.name, WorkItem.name].freeze

  TARGET_TYPES = HashWithIndifferentAccess.new(
    issue: Issue,
    milestone: Milestone,
    merge_request: MergeRequest,
    note: Note,
    project: Project,
    snippet: Snippet,
    user: User,
    wiki: WikiPage::Meta,
    design: DesignManagement::Design
  ).freeze

  RESET_PROJECT_ACTIVITY_INTERVAL = 1.hour
  REPOSITORY_UPDATED_AT_INTERVAL = 5.minutes
  CONTRIBUTABLE_TARGET_TYPES = %w[MergeRequest Issue WorkItem].freeze

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
  belongs_to :personal_namespace, class_name: "Namespaces::UserNamespace"

  belongs_to :target, -> {
    # If the association for "target" defines an "author" association we want to
    # eager-load this so Banzai & friends don't end up performing N+1 queries to
    # get the authors of notes, issues, etc. (likewise for "noteable").
    incs = %i[author noteable work_item_type].select do |a|
      reflections['events'].active_record.reflect_on_association(a)
    end

    incs.reduce(self) { |obj, a| obj.includes(a) }
  }, polymorphic: true # rubocop:disable Cop/PolymorphicAssociations

  has_one :push_event_payload

  # Callbacks
  before_save :ensure_sharding_key
  after_create :update_project

  # Scopes
  scope :recent, -> { reorder(id: :desc) }
  scope :for_wiki_page, -> { where(target_type: 'WikiPage::Meta') }
  scope :for_design, -> { where(target_type: 'DesignManagement::Design') }
  scope :for_issue, -> { where(target_type: ISSUE_TYPES) }
  scope :for_merge_request, -> { where(target_type: 'MergeRequest') }
  scope :for_fingerprint, ->(fingerprint) do
    fingerprint.present? ? where(fingerprint: fingerprint) : none
  end
  scope :for_action, ->(action) { where(action: action) }
  scope :created_between, ->(start_time, end_time) { where(created_at: start_time..end_time) }
  scope :count_by_dates, ->(date_interval) { group("DATE(created_at + #{date_interval})").count }

  scope :contributions, -> do
    contribution_actions = [actions[:pushed], actions[:commented]]
    target_contribution_actions = [actions[:created], actions[:closed], actions[:merged], actions[:approved]]

    where(
      'action IN (?) OR (target_type IN (?) AND action IN (?))',
      contribution_actions,
      CONTRIBUTABLE_TARGET_TYPES, target_contribution_actions
    )
  end

  scope :with_associations, -> do
    # We're using preload for "push_event_payload" as otherwise the association
    # is not always available (depending on the query being built).
    includes(:project, project: [:project_feature, :import_data, :namespace])
      .preload(:author, :target, :push_event_payload)
  end

  scope :for_milestone_id, ->(milestone_id) { where(target_type: "Milestone", target_id: milestone_id) }
  scope :for_wiki_meta, ->(meta) { where(target_type: 'WikiPage::Meta', target_id: meta.id) }
  scope :created_at, ->(time) { where(created_at: time) }
  scope :with_target, -> { preload(:target) }

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

  def work_item?
    target_type == 'WorkItem'
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

      Wiki.for_container(project || group, author).find_page(target.canonical_slug)
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

  def wiki_page_note?
    note? && note.for_wiki_page?
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

  def ensure_sharding_key
    return unless group_id.nil? && project_id.nil? && personal_namespace_id.nil?

    self.personal_namespace_id = author.namespace_id
  end

  def update_project
    return unless project_id.present?

    reset_project_activity
    set_last_repository_updated_at if push_action?
  end

  def reset_project_activity
    return unless project_id.present?

    # Don't bother updating if we know the project was updated recently.
    return if recent_update?

    # At this point it's possible for multiple threads/processes to try to
    # update the project. Only one query should actually perform the update,
    # hence we add the extra WHERE clause for last_activity_at.
    Project.unscoped.where(id: project_id)
      .where('last_activity_at <= ?', RESET_PROJECT_ACTIVITY_INTERVAL.ago)
      .touch_all(:last_activity_at, time: created_at)

    Gitlab::InactiveProjectsDeletionWarningTracker.new(project_id).reset
  end

  def authored_by?(user)
    user ? author_id == user.id : false
  end

  def to_partial_path
    # We are intentionally using `Event` rather than `self.class` so that
    # subclasses also use the `Event` implementation.
    Event._to_partial_path
  end

  def has_no_project_and_group?
    project_id.nil? && group_id.nil?
  end

  protected

  def capability
    @capability ||= capabilities.flat_map do |ability, syms|
      if syms.any? { |sym| send(sym) } # rubocop: disable GitlabSecurity/PublicSend
        [ability]
      else
        []
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
      read_note: %i[note?],
      read_work_item: %i[work_item?]
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

  def recent_repository_update?
    project.last_repository_updated_at > REPOSITORY_UPDATED_AT_INTERVAL.ago
  end

  def set_last_repository_updated_at
    Project.unscoped.where(id: project_id)
      .where("last_repository_updated_at < ? OR last_repository_updated_at IS NULL", REPOSITORY_UPDATED_AT_INTERVAL.ago)
      .touch_all(:last_repository_updated_at, time: created_at)
  end

  def design_action_names
    {
      created: 'added',
      updated: 'updated',
      destroyed: 'removed'
    }
  end

  def action_enum_value
    self.class.actions[action]
  end
end

Event.prepend_mod_with('Event')
