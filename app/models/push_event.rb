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

  # The "data" field must not be set for push events since it's not used and a
  # waste of space.
  validates :data, absence: true

  # These fields are also not used for push events, thus storing them would be a
  # waste.
  validates :target_id, absence: true
  validates :target_type, absence: true

  def self.sti_name
    PUSHED
  end

  def push?
    true
  end

  def push_with_commits?
    !!(commit_from && commit_to)
  end

  def tag?
    return super unless push_event_payload

    push_event_payload.tag?
  end

  def branch?
    return super unless push_event_payload

    push_event_payload.branch?
  end

  def valid_push?
    return super unless push_event_payload

    push_event_payload.ref.present?
  end

  def new_ref?
    return super unless push_event_payload

    push_event_payload.created?
  end

  def rm_ref?
    return super unless push_event_payload

    push_event_payload.removed?
  end

  def commit_from
    return super unless push_event_payload

    push_event_payload.commit_from
  end

  def commit_to
    return super unless push_event_payload

    push_event_payload.commit_to
  end

  def ref_name
    return super unless push_event_payload

    push_event_payload.ref
  end

  def ref_type
    return super unless push_event_payload

    push_event_payload.ref_type
  end

  def branch_name
    return super unless push_event_payload

    ref_name
  end

  def tag_name
    return super unless push_event_payload

    ref_name
  end

  def commit_title
    return super unless push_event_payload

    push_event_payload.commit_title
  end

  def commit_id
    commit_to || commit_from
  end

  def commits_count
    return super unless push_event_payload

    push_event_payload.commit_count
  end

  def validate_push_action
    return if action == PUSHED

    errors.add(:action, "the action #{action.inspect} is not valid")
  end
end
