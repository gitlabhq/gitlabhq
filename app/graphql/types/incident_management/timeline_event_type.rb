# frozen_string_literal: true

module Types
  module IncidentManagement
    class TimelineEventType < BaseObject
      graphql_name 'TimelineEventType'
      description 'Describes an incident management timeline event'

      authorize :read_incident_management_timeline_event

      field :id,
        Types::GlobalIDType[::IncidentManagement::TimelineEvent],
        null: false,
        description: 'ID of the timeline event.'

      field :author,
        Types::UserType,
        null: true,
        description: 'User that created the timeline event.'

      field :updated_by_user,
        Types::UserType,
        null: true,
        description: 'User that updated the timeline event.'

      field :incident,
        Types::IssueType,
        null: false,
        description: 'Incident of the timeline event.'

      field :note,
        GraphQL::Types::String,
        null: true,
        description: 'Text note of the timeline event.'

      field :promoted_from_note,
        Types::Notes::NoteType,
        null: true,
        description: 'Note from which the timeline event was created.'

      field :editable,
        GraphQL::Types::Boolean,
        null: false,
        description: 'Indicates the timeline event is editable.'

      field :action,
        GraphQL::Types::String,
        null: false,
        description: 'Indicates the timeline event icon.'

      field :occurred_at,
        Types::TimeType,
        null: false,
        description: 'Timestamp when the event occurred.'

      field :timeline_event_tags,
        ::Types::IncidentManagement::TimelineEventTagType.connection_type,
        null: true,
        description: 'Tags for the incident timeline event.',
        extras: [:lookahead],
        resolver: Resolvers::IncidentManagement::TimelineEventTagsResolver

      field :created_at,
        Types::TimeType,
        null: false,
        description: 'Timestamp when the event created.'

      field :updated_at,
        Types::TimeType,
        null: false,
        description: 'Timestamp when the event updated.'

      markdown_field :note_html, null: true, description: 'HTML note of the timeline event.'
    end
  end
end
