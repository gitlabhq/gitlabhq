# Service class for creating push event payloads as stored in the
# "push_event_payloads" table.
#
# Example:
#
#     data = Gitlab::DataBuilder::Push.build(...)
#     event = Event.create(...)
#
#     PushEventPayloadService.new(event, data).execute
class PushEventPayloadService
  # event - The event this push payload belongs to.
  # push_data - A Hash produced by `Gitlab::DataBuilder::Push.build` to use for
  #             building the push payload.
  def initialize(event, push_data)
    @event = event
    @push_data = push_data
  end

  # Creates and returns a new PushEventPayload row.
  #
  # This method will raise upon encountering validation errors.
  #
  # Returns an instance of PushEventPayload.
  def execute
    @event.build_push_event_payload(
      commit_count: commit_count,
      action: action,
      ref_type: ref_type,
      commit_from: commit_from_id,
      commit_to: commit_to_id,
      ref: trimmed_ref,
      commit_title: commit_title,
      event_id: @event.id
    )

    @event.push_event_payload.save!
    @event.push_event_payload
  end

  # Returns the commit title to use.
  #
  # The commit title is limited to the first line and a maximum of 70
  # characters.
  def commit_title
    commit = @push_data.fetch(:commits).last

    return nil unless commit && commit[:message]

    raw_msg = commit[:message]

    # Find where the first line ends, without turning the entire message into an
    # Array of lines (this is a waste of memory for large commit messages).
    index = raw_msg.index("\n")
    message = index ? raw_msg[0..index] : raw_msg

    message.strip.truncate(70)
  end

  def commit_from_id
    if create?
      nil
    else
      revision_before
    end
  end

  def commit_to_id
    if remove?
      nil
    else
      revision_after
    end
  end

  def commit_count
    @push_data.fetch(:total_commits_count)
  end

  def ref
    @push_data.fetch(:ref)
  end

  def revision_before
    @push_data.fetch(:before)
  end

  def revision_after
    @push_data.fetch(:after)
  end

  def trimmed_ref
    Gitlab::Git.ref_name(ref)
  end

  def create?
    Gitlab::Git.blank_ref?(revision_before)
  end

  def remove?
    Gitlab::Git.blank_ref?(revision_after)
  end

  def action
    if create?
      :created
    elsif remove?
      :removed
    else
      :pushed
    end
  end

  def ref_type
    if Gitlab::Git.tag_ref?(ref)
      :tag
    else
      :branch
    end
  end
end
