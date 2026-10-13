# frozen_string_literal: true

module Types
  module MergeRequests
    class ResourceLabelEventType < BaseObject
      graphql_name 'MergeRequestResourceLabelEvent'
      description 'Label event on a merge request.'

      authorize :read_resource_label_event
      authorize_granular_token permissions: :read_merge_request_label_event,
        boundary: :merge_request_project, boundary_type: :project

      field :id, ::Types::GlobalIDType[::ResourceLabelEvent],
        null: false,
        description: 'Global ID of the label event.'

      field :action, ::Types::MergeRequests::ResourceLabelEventActionEnum,
        null: false,
        description: 'Action of the label event.'

      field :created_at, ::Types::TimeType,
        null: false,
        description: 'Timestamp of when the label event was created.'

      field :label, ::Types::LabelType,
        null: true,
        description: 'Label associated with the event. Null if the label was deleted.'

      field :user, ::Types::UserType,
        null: true,
        description: 'User who triggered the event.'
    end
  end
end
