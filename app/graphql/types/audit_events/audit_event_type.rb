# frozen_string_literal: true

# rubocop: disable Graphql/AuthorizeTypes -- Authorization is handled in the ComplianceViolationType from which this is called
module Types
  module AuditEvents
    class AuditEventType < ::Types::BaseObject
      graphql_name 'AuditEvent'
      description 'Audit event.'

      field :id, GraphQL::Types::ID,
        null: false, description: 'Audit Event ID.'

      field :created_at, Types::TimeType,
        null: false, description: 'Timestamp when the audit event was created.'

      field :author, Types::UserType,
        null: true, description: 'User who triggered the event.'

      field :event_name, GraphQL::Types::String,
        null: true, description: 'Name of the event.'

      field :details, GraphQL::Types::String,
        null: true, description: 'Additional details of the audit event.'

      field :target_type, GraphQL::Types::String,
        null: true, description: 'Type of the target of the audit event.'

      field :target_details, GraphQL::Types::String,
        null: true, description: 'Additional details of the target.'

      field :target_id, GraphQL::Types::ID, # rubocop:disable GraphQL/ExtractType -- not needed as it is part of audit event only
        null: true, description: 'ID of the target of the audit event.'

      field :ip_address, GraphQL::Types::String,
        null: true, description: 'IP address of the user.'

      field :entity_path, GraphQL::Types::String,
        null: true, description: 'Path of the entity.'

      field :entity_id, GraphQL::Types::ID,
        null: true, description: 'ID of the entity.'

      field :entity_type, GraphQL::Types::String, # rubocop:disable GraphQL/ExtractType -- not needed as it is part of audit event only
        null: true, description: 'Type of the entity.'

      field :project, Types::ProjectType,
        null: true, description: 'Project associated with the audit event.'

      field :group, Types::GroupType,
        null: true, description: 'Group associated with the audit event.'

      field :user, Types::UserType,
        null: true, description: 'User associated with the audit event.'

      def group
        object.group if object.respond_to?(:group)
      end

      def project
        object.project if object.respond_to?(:project)
      end
    end
  end
end
# rubocop: enable Graphql/AuthorizeTypes
