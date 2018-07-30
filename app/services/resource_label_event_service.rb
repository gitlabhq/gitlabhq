# frozen_string_literal: true

module ResourceLabelEventService
  prepend EE::ResourceLabelEventService

  extend self

  def change_labels(resource, user, added_labels, removed_labels)
    label_hash = {
      resource_column(resource) => resource.id,
      user_id: user.id,
      created_at: Time.now
    }

    labels = added_labels.map do |label|
      label_hash.merge(label_id: label.id, action: ResourceLabelEvent.actions['add'])
    end
    labels += removed_labels.map do |label|
      label_hash.merge(label_id: label.id, action: ResourceLabelEvent.actions['remove'])
    end

    Gitlab::Database.bulk_insert(ResourceLabelEvent.table_name, labels)
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
