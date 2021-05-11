# frozen_string_literal: true

# EventCreateService class
#
# Used for creating events feed on dashboard after certain user action
#
# Ex.
#   EventCreateService.new.new_issue(issue, current_user)
#
class EventCreateService
  IllegalActionError = Class.new(StandardError)

  def open_issue(issue, current_user)
    create_record_event(issue, current_user, :created)
  end

  def close_issue(issue, current_user)
    create_record_event(issue, current_user, :closed)
  end

  def reopen_issue(issue, current_user)
    create_record_event(issue, current_user, :reopened)
  end

  def open_mr(merge_request, current_user)
    create_record_event(merge_request, current_user, :created).tap do
      track_event(event_action: :created, event_target: MergeRequest, author_id: current_user.id)
    end
  end

  def close_mr(merge_request, current_user)
    create_record_event(merge_request, current_user, :closed).tap do
      track_event(event_action: :closed, event_target: MergeRequest, author_id: current_user.id)
    end
  end

  def reopen_mr(merge_request, current_user)
    create_record_event(merge_request, current_user, :reopened)
  end

  def merge_mr(merge_request, current_user)
    create_record_event(merge_request, current_user, :merged).tap do
      track_event(event_action: :merged, event_target: MergeRequest, author_id: current_user.id)
    end
  end

  def open_milestone(milestone, current_user)
    create_record_event(milestone, current_user, :created)
  end

  def close_milestone(milestone, current_user)
    create_record_event(milestone, current_user, :closed)
  end

  def reopen_milestone(milestone, current_user)
    create_record_event(milestone, current_user, :reopened)
  end

  def destroy_milestone(milestone, current_user)
    create_record_event(milestone, current_user, :destroyed)
  end

  def leave_note(note, current_user)
    create_record_event(note, current_user, :commented).tap do
      if note.is_a?(DiffNote) && note.for_merge_request?
        track_event(event_action: :commented, event_target: MergeRequest, author_id: current_user.id)
      end
    end
  end

  def join_project(project, current_user)
    create_event(project, current_user, :joined)
  end

  def leave_project(project, current_user)
    create_event(project, current_user, :left)
  end

  def expired_leave_project(project, current_user)
    create_event(project, current_user, :expired)
  end

  def create_project(project, current_user)
    create_event(project, current_user, :created)
  end

  def push(project, current_user, push_data)
    create_push_event(PushEventPayloadService, project, current_user, push_data)
  end

  def bulk_push(project, current_user, push_data)
    create_push_event(BulkPushEventPayloadService, project, current_user, push_data)
  end

  def save_designs(current_user, create: [], update: [])
    records = create.zip([:created].cycle) + update.zip([:updated].cycle)
    return [] if records.empty?

    create_record_events(records, current_user)
  end

  def destroy_designs(designs, current_user)
    return [] unless designs.present?

    create_record_events(designs.zip([:destroyed].cycle), current_user)
  end

  # Create a new wiki page event
  #
  # @param [WikiPage::Meta] wiki_page_meta The event target
  # @param [User] author The event author
  # @param [Symbol] action One of the Event::WIKI_ACTIONS
  # @param [String] fingerprint The de-duplication fingerprint
  #
  # The fingerprint, if provided, should be sufficient to find duplicate events.
  # Suitable values would be, for example, the current page SHA.
  #
  # @return [Event] the event
  def wiki_event(wiki_page_meta, author, action, fingerprint)
    raise IllegalActionError, action unless Event::WIKI_ACTIONS.include?(action)

    track_event(event_action: action, event_target: wiki_page_meta.class, author_id: author.id)

    duplicate = Event.for_wiki_meta(wiki_page_meta).for_fingerprint(fingerprint).first
    return duplicate if duplicate.present?

    create_record_event(wiki_page_meta, author, action, fingerprint.presence)
  end

  def approve_mr(merge_request, current_user)
    create_record_event(merge_request, current_user, :approved)
  end

  private

  def create_record_event(record, current_user, status, fingerprint = nil)
    create_event(record.resource_parent, current_user, status,
                 fingerprint: fingerprint,
                 target_id: record.id,
                 target_type: record.class.name)
  end

  # If creating several events, this method will insert them all in a single
  # statement
  #
  # @param [[Eventable, Symbol, String]] a list of tuples of records, a valid status, and fingerprint
  # @param [User] the author of the event
  def create_record_events(tuples, current_user)
    base_attrs = {
      created_at: Time.now.utc,
      updated_at: Time.now.utc,
      author_id: current_user.id
    }

    attribute_sets = tuples.map do |record, status, fingerprint|
      action = Event.actions[status]
      raise IllegalActionError, "#{status} is not a valid status" if action.nil?

      parent_attrs(record.resource_parent)
        .merge(base_attrs)
        .merge(action: action, fingerprint: fingerprint, target_id: record.id, target_type: record.class.name)
    end

    result = Event.insert_all(attribute_sets, returning: %w[id])

    tuples.each do |record, status, _|
      track_event(event_action: status, event_target: record.class, author_id: current_user.id)
    end

    result
  end

  def create_push_event(service_class, project, current_user, push_data)
    # We're using an explicit transaction here so that any errors that may occur
    # when creating push payload data will result in the event creation being
    # rolled back as well.
    event = Event.transaction do
      new_event = create_event(project, current_user, :pushed)

      service_class.new(new_event, push_data).execute

      new_event
    end

    track_event(event_action: :pushed, event_target: Project, author_id: current_user.id)

    Users::LastPushEventService.new(current_user)
      .cache_last_push_event(event)

    Users::ActivityService.new(current_user).execute
  end

  def create_event(resource_parent, current_user, status, attributes = {})
    attributes.reverse_merge!(
      action: status,
      author_id: current_user.id
    )
    attributes.merge!(parent_attrs(resource_parent))

    if attributes[:fingerprint].present?
      Event.safe_find_or_create_by!(attributes)
    else
      Event.create!(attributes)
    end
  end

  def parent_attrs(resource_parent)
    resource_parent_attr = case resource_parent
                           when Project
                             :project_id
                           when Group
                             :group_id
                           end

    return {} unless resource_parent_attr

    { resource_parent_attr => resource_parent.id }
  end

  def track_event(**params)
    Gitlab::UsageDataCounters::TrackUniqueEvents.track_event(**params)
  end
end

EventCreateService.prepend_mod_with('EventCreateService')
