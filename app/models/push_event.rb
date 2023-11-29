# frozen_string_literal: true

class PushEvent < Event
  self.allow_legacy_sti_class = true

  # This validation exists so we can't accidentally use PushEvent with a
  # different "action" value.
  validate :validate_push_action

  # The project is required to build links to commits, commit ranges, etc.
  #
  # We're just validating the presence of the ID here as foreign key constraints
  # should ensure the ID points to a valid project.
  validates :project_id, presence: true

  # These fields are also not used for push events, thus storing them would be a
  # waste.
  validates :target_id, absence: true
  validates :target_type, absence: true

  delegate :branch?, to: :push_event_payload
  delegate :tag?, to: :push_event_payload
  delegate :commit_from, to: :push_event_payload
  delegate :commit_to, to: :push_event_payload
  delegate :ref_type, to: :push_event_payload
  delegate :commit_title, to: :push_event_payload

  delegate :commit_count, to: :push_event_payload
  alias_method :commits_count, :commit_count

  delegate :ref_count, to: :push_event_payload

  # Returns events of pushes that either pushed to an existing ref or created a
  # new one.
  def self.created_or_pushed
    actions = [
      PushEventPayload.actions[:pushed],
      PushEventPayload.actions[:created]
    ]

    joins(:push_event_payload)
      .where(push_event_payloads: { action: actions })
  end

  # Returns events of pushes to a branch.
  def self.branch_events
    ref_type = PushEventPayload.ref_types[:branch]

    joins(:push_event_payload)
      .where(push_event_payloads: { ref_type: ref_type })
  end

  # Returns PushEvent instances for which no merge requests have been created.
  def self.without_existing_merge_requests
    existing_mrs = MergeRequest.except(:order, :where)
      .select(1)
      .where('merge_requests.source_project_id = events.project_id')
      .where('merge_requests.source_branch = push_event_payloads.ref')
      .with_state(:opened)

    # For reasons unknown the use of #eager_load will result in the
    # "push_event_payload" association not being set. Because of this we're
    # using "joins" here, which does mean an additional query needs to be
    # executed in order to retrieve the "push_event_association" when the
    # returned PushEvent is used.
    joins(:push_event_payload)
      .where('NOT EXISTS (?)', existing_mrs)
      .created_or_pushed
      .branch_events
  end

  def self.sti_name
    actions[:pushed]
  end

  def push_action?
    true
  end

  def push_with_commits?
    !!(commit_from && commit_to)
  end

  def valid_push?
    push_event_payload.ref.present?
  end

  def new_ref?
    push_event_payload.created?
  end

  def rm_ref?
    push_event_payload.removed?
  end

  def md_ref?
    !(rm_ref? || new_ref?)
  end

  def ref_name
    push_event_payload.ref
  end

  alias_method :branch_name, :ref_name
  alias_method :tag_name, :ref_name

  def commit_id
    commit_to || commit_from
  end

  def last_push_to_non_root?
    branch? && project.default_branch != branch_name
  end

  def validate_push_action
    return if pushed_action?

    errors.add(:action, "the action #{action.inspect} is not valid")
  end
end
