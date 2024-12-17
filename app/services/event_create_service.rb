# frozen_string_literal: true

# EventCreateService class
#
# Used for creating events feed on dashboard after certain user action
#
# Ex.
#   EventCreateService.new.new_issue(issue, current_user)
#
class EventCreateService
  include Gitlab::InternalEventsTracking

  IllegalActionError = Class.new(StandardError)

  DEGIGN_EVENT_LABEL = 'usage_activity_by_stage_monthly.create.action_monthly_active_users_design_management'
  MR_EVENT_LABEL = 'usage_activity_by_stage_monthly.create.merge_requests_users'
  MR_EVENT_PROPERTY = 'merge_request_action'

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
      Gitlab::UsageDataCounters::HLLRedisCounter.track_event(:merge_request_action, values: current_user.id)
      track_snowplow_event(
        action: :created,
        project: merge_request.project,
        user: current_user,
        label: MR_EVENT_LABEL,
        property: MR_EVENT_PROPERTY
      )
    end
  end

  def close_mr(merge_request, current_user)
    create_record_event(merge_request, current_user, :closed).tap do
      Gitlab::UsageDataCounters::HLLRedisCounter.track_event(:merge_request_action, values: current_user.id)
      track_snowplow_event(
        action: :closed,
        project: merge_request.project,
        user: current_user,
        label: MR_EVENT_LABEL,
        property: MR_EVENT_PROPERTY
      )
    end
  end

  def reopen_mr(merge_request, current_user)
    create_record_event(merge_request, current_user, :reopened)
  end

  def merge_mr(merge_request, current_user)
    create_record_event(merge_request, current_user, :merged).tap do
      Gitlab::UsageDataCounters::HLLRedisCounter.track_event(:merge_request_action, values: current_user.id)
      track_snowplow_event(
        action: :merged,
        project: merge_request.project,
        user: current_user,
        label: MR_EVENT_LABEL,
        property: MR_EVENT_PROPERTY
      )
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
        Gitlab::UsageDataCounters::HLLRedisCounter.track_event(:merge_request_action, values: current_user.id)
        track_snowplow_event(
          action: :commented,
          project: note.project,
          user: current_user,
          label: MR_EVENT_LABEL,
          property: MR_EVENT_PROPERTY
        )
      end
    end
  end

  def join_source(source, current_user)
    return unless source.is_a?(Project)

    create_event(source, current_user, :joined)
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

    event_meta = { user: current_user, label: DEGIGN_EVENT_LABEL, property: :design_action }
    track_snowplow_event(action: :create, project: create.first.project, **event_meta) if create.any?

    track_snowplow_event(action: :update, project: update.first.project, **event_meta) if update.any?

    inserted_events = create_record_events(records, current_user)

    Gitlab::UsageDataCounters::HLLRedisCounter.track_event(:design_action, values: current_user.id)
    Gitlab::UsageDataCounters::HLLRedisCounter.track_event(:git_write_action, values: current_user.id)

    inserted_events
  end

  def destroy_designs(designs, current_user)
    return [] unless designs.present?

    track_snowplow_event(
      action: :destroy,
      project: designs.first.project,
      user: current_user,
      label: DEGIGN_EVENT_LABEL,
      property: :design_action
    )

    inserted_events = create_record_events(designs.zip([:destroyed].cycle), current_user)

    Gitlab::UsageDataCounters::HLLRedisCounter.track_event(:design_action, values: current_user.id)
    Gitlab::UsageDataCounters::HLLRedisCounter.track_event(:git_write_action, values: current_user.id)

    inserted_events
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

    Gitlab::UsageDataCounters::HLLRedisCounter.track_event(:git_write_action, values: author.id)

    track_internal_event("performed_wiki_action",
      project: wiki_page_meta.project,
      user: author,
      additional_properties: { label: action.to_s }
    )

    duplicate = Event.for_wiki_meta(wiki_page_meta).for_fingerprint(fingerprint).first
    return duplicate if duplicate.present?

    create_record_event(wiki_page_meta, author, action, fingerprint.presence)
  end

  def approve_mr(merge_request, current_user)
    create_record_event(merge_request, current_user, :approved)
  end

  private

  def create_record_event(record, current_user, status, fingerprint = nil)
    create_event(
      record.resource_parent,
      current_user,
      status,
      fingerprint: fingerprint,
      target_id: record.id,
      target_type: record.class.name
    )
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

      parent_attrs(record.resource_parent, current_user)
        .merge(base_attrs)
        .merge(action: action, fingerprint: fingerprint, target_id: record.id, target_type: record.class.name)
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

    Gitlab::UsageDataCounters::HLLRedisCounter.track_event(:project_action, values: current_user.id)
    Gitlab::UsageDataCounters::HLLRedisCounter.track_event(:git_write_action, values: current_user.id)

    namespace = project.namespace
    Gitlab::Tracking.event(
      self.class.to_s,
      :push,
      label: 'usage_activity_by_stage_monthly.create.action_monthly_active_users_project_repo',
      namespace: namespace,
      user: current_user,
      project: project,
      property: 'project_action',
      context: [Gitlab::Tracking::ServicePingContext.new(data_source: :redis_hll, event: 'project_action').to_context]
    )

    Users::LastPushEventService.new(current_user)
      .cache_last_push_event(event)

    Users::ActivityService.new(author: current_user, namespace: namespace, project: project).execute

    Gitlab::EventStore.publish(
      Users::ActivityEvent.new(data: {
        user_id: current_user.id,
        namespace_id: project.root_ancestor.id
      })
    )
  end

  def create_event(resource_parent, current_user, status, attributes = {})
    attributes.reverse_merge!(
      action: status,
      author_id: current_user.id
    )
    attributes.merge!(parent_attrs(resource_parent, current_user))

    if attributes[:fingerprint].present?
      Event.safe_find_or_create_by!(attributes)
    else
      Event.create!(attributes)
    end
  end

  def parent_attrs(resource_parent, current_user)
    resource_parent_attr = case resource_parent
                           when Project
                             :project_id
                           when Group
                             :group_id
                           end

    return { personal_namespace_id: current_user.namespace_id }.compact unless resource_parent_attr

    { resource_parent_attr => resource_parent.id }
  end

  def track_snowplow_event(action:, project:, user:, label:, property:)
    Gitlab::Tracking.event(
      self.class.to_s,
      action.to_s,
      label: label,
      namespace: project.namespace,
      user: user,
      project: project,
      property: property.to_s,
      context: [Gitlab::Tracking::ServicePingContext.new(data_source: :redis_hll, event: property.to_s).to_context]
    )
  end
end

EventCreateService.prepend_mod_with('EventCreateService')
