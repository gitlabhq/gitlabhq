# frozen_string_literal: true

module Types
  module IncidentManagement
    class TimelineEventTagType < BaseObject
      graphql_name 'TimelineEventTagType'

      description 'Describes a tag on an incident management timeline event.'

      authorize :read_incident_management_timeline_event_tag

      field :id,
        Types::GlobalIDType[::IncidentManagement::TimelineEventTag],
        null: false,
        description: 'ID of the timeline event tag.'

      field :name,
        GraphQL::Types::String,
        null: false,
        description: 'Name of the timeline event tag.'
    end
  end
end
