# frozen_string_literal: true

module ResourceEvents
  class ChangeLabelsService
    attr_reader :resource, :user

    def initialize(resource, user)
      @resource = resource
      @user = user
    end

    def execute(added_labels: [], removed_labels: [])
      label_hash = {
        resource_column(resource) => resource.id,
        user_id: user.id,
        created_at: resource.system_note_timestamp
      }

      labels = added_labels.map do |label|
        label_hash.merge(label_id: label.id, action: ResourceLabelEvent.actions['add'])
      end
      labels += removed_labels.map do |label|
        label_hash.merge(label_id: label.id, action: ResourceLabelEvent.actions['remove'])
      end

      ids = ApplicationRecord.legacy_bulk_insert(ResourceLabelEvent.table_name, labels, return_ids: true) # rubocop:disable Gitlab/BulkInsert

      if resource.is_a?(Issue)
        events = ResourceLabelEvent.id_in(ids).to_a
        events.first.trigger_note_subscription_create(events: events) if events.any?
      end

      create_timeline_events_from(added_labels: added_labels, removed_labels: removed_labels)
      resource.broadcast_notes_changed

      return unless resource.is_a?(Issue)

      Gitlab::UsageDataCounters::IssueActivityUniqueCounter.track_issue_label_changed_action(
        author: user, project: resource.project)

      events
    end

    private

    def resource_column(resource)
      case resource
      when Issue
        :issue_id
      when MergeRequest
        :merge_request_id
      else
        raise ArgumentError, "Unknown resource type #{resource.class.name}"
      end
    end

    def create_timeline_events_from(added_labels: [], removed_labels: [])
      return unless resource.incident_type_issue?

      IncidentManagement::TimelineEvents::CreateService.change_labels(
        resource,
        user,
        added_labels: added_labels,
        removed_labels: removed_labels
      )
    end
  end
end

ResourceEvents::ChangeLabelsService.prepend_mod_with('ResourceEvents::ChangeLabelsService')
