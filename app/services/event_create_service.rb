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
    create_resource_event(issue, current_user, :opened)

    create_record_event(issue, current_user, :created)
  end

  def close_issue(issue, current_user)
    create_resource_event(issue, current_user, :closed)

    create_record_event(issue, current_user, :closed)
  end

  def reopen_issue(issue, current_user)
    create_resource_event(issue, current_user, :reopened)

    create_record_event(issue, current_user, :reopened)
  end

  def open_mr(merge_request, current_user)
    create_resource_event(merge_request, current_user, :opened)

    create_record_event(merge_request, current_user, :created)
  end

  def close_mr(merge_request, current_user)
    create_resource_event(merge_request, current_user, :closed)

    create_record_event(merge_request, current_user, :closed)
  end

  def reopen_mr(merge_request, current_user)
    create_resource_event(merge_request, current_user, :reopened)

    create_record_event(merge_request, current_user, :reopened)
  end

  def merge_mr(merge_request, current_user)
    create_resource_event(merge_request, current_user, :merged)

    create_record_event(merge_request, current_user, :merged)
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
    create_record_event(note, current_user, :commented)
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
    created = create.group_by(&:project).flat_map do |project, designs|
      Feature.enabled?(:design_activity_events, project) ? designs : []
    end.to_set
    updated = update.group_by(&:project).flat_map do |project, designs|
      Feature.enabled?(:design_activity_events, project) ? designs : []
    end.to_set
    return [] if created.empty? && updated.empty?

    records = created.zip([:created].cycle) + updated.zip([:updated].cycle)

    create_record_events(records, current_user)
  end

  def destroy_designs(designs, current_user)
    designs = designs.select do |design|
      Feature.enabled?(:design_activity_events, design.project)
    end
    return [] unless designs.present?

    create_record_events(designs.zip([:destroyed].cycle), current_user)
  end

  # Create a new wiki page event
  #
  # @param [WikiPage::Meta] wiki_page_meta The event target
  # @param [User] author The event author
  # @param [Symbol] action One of the Event::WIKI_ACTIONS
  #
  # @return a tuple of event and either :found or :created
  def wiki_event(wiki_page_meta, author, action)
    return unless Feature.enabled?(:wiki_events)

    raise IllegalActionError, action unless Event::WIKI_ACTIONS.include?(action)

    if duplicate = existing_wiki_event(wiki_page_meta, action)
      return duplicate
    end

    event = create_record_event(wiki_page_meta, author, action)
    # Ensure that the event is linked in time to the metadata, for non-deletes
    unless event.destroyed_action?
      time_stamp = wiki_page_meta.updated_at
      event.update_columns(updated_at: time_stamp, created_at: time_stamp)
    end

    event
  end

  private

  def existing_wiki_event(wiki_page_meta, action)
    if Event.actions.fetch(action) == Event.actions[:destroyed]
      most_recent = Event.for_wiki_meta(wiki_page_meta).recent.first
      return most_recent if most_recent.present? && Event.actions[most_recent.action] == Event.actions[action]
    else
      Event.for_wiki_meta(wiki_page_meta).created_at(wiki_page_meta.updated_at).first
    end
  end

  def create_record_event(record, current_user, status)
    create_event(record.resource_parent, current_user, status,
                 target_id: record.id, target_type: record.class.name)
  end

  # If creating several events, this method will insert them all in a single
  # statement
  #
  # @param [[Eventable, Symbol]] a list of pairs of records and a valid status
  # @param [User] the author of the event
  def create_record_events(pairs, current_user)
    base_attrs = {
      created_at: Time.now.utc,
      updated_at: Time.now.utc,
      author_id: current_user.id
    }

    attribute_sets = pairs.map do |record, status|
      action = Event.actions[status]
      raise IllegalActionError, "#{status} is not a valid status" if action.nil?

      parent_attrs(record.resource_parent)
        .merge(base_attrs)
        .merge(action: action, target_id: record.id, target_type: record.class.name)
    end

    Event.insert_all(attribute_sets, returning: %w[id])
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

    Event.create!(attributes)
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

  def create_resource_event(issuable, current_user, status)
    return unless state_change_tracking_enabled?(issuable)

    ResourceEvents::ChangeStateService.new(resource: issuable, user: current_user)
      .execute(status)
  end

  def state_change_tracking_enabled?(issuable)
    issuable&.respond_to?(:resource_state_events) &&
      ::Feature.enabled?(:track_resource_state_change_events, issuable&.project)
  end
end

EventCreateService.prepend_if_ee('EE::EventCreateService')
