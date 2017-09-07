class PushEvent < Event
  # This validation exists so we can't accidentally use PushEvent with a
  # different "action" value.
  validate :validate_push_action

  # Authors are required as they're used to display who pushed data.
  #
  # We're just validating the presence of the ID here as foreign key constraints
  # should ensure the ID points to a valid user.
  validates :author_id, presence: true

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

  def self.sti_name
    PUSHED
  end

  def push?
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
    return if action == PUSHED

    errors.add(:action, "the action #{action.inspect} is not valid")
  end
end
