# frozen_string_literal: true

module Types
  module AuditEvents
    class DefinitionType < ::Types::BaseObject
      graphql_name 'AuditEventDefinition'
      description 'Represents the YAML definitions for audit events defined ' \
        'in `ee/config/audit_events/types/<event-type-name>.yml` ' \
        'and `config/audit_events/types/<event-type-name>.yml`.'

      authorize :audit_event_definitions

      field :name, GraphQL::Types::String,
        null: false,
        description: 'Key name of the audit event.'

      field :description, GraphQL::Types::String,
        null: false,
        description: 'Description of what action the audit event tracks.'

      field :introduced_by_issue, GraphQL::Types::String,
        null: true,
        description: 'Link to the issue introducing the event. For older' \
          'audit events, it can be a commit URL rather than a' \
          'merge request URL.'

      field :introduced_by_mr, GraphQL::Types::String,
        null: true,
        description: 'Link to the merge request introducing the event. For' \
          'older audit events, it can be a commit URL rather than' \
          'a merge request URL.'

      field :feature_category, GraphQL::Types::String,
        null: false,
        description: 'Feature category associated with the event.'

      field :milestone, GraphQL::Types::String,
        null: false,
        description: 'Milestone the event was introduced in.'

      field :saved_to_database, GraphQL::Types::Boolean,
        null: false,
        description: 'Indicates if the event is saved to PostgreSQL database.'

      field :streamed, GraphQL::Types::Boolean,
        null: false,
        description: 'Indicates if the event is streamed to an external destination.'
    end
  end
end
