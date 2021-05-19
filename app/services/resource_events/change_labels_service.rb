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

      Gitlab::Database.bulk_insert(ResourceLabelEvent.table_name, labels) # rubocop:disable Gitlab/BulkInsert
      resource.expire_note_etag_cache

      Gitlab::UsageDataCounters::IssueActivityUniqueCounter.track_issue_label_changed_action(author: user) if resource.is_a?(Issue)
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
  end
end

ResourceEvents::ChangeLabelsService.prepend_mod_with('ResourceEvents::ChangeLabelsService')
