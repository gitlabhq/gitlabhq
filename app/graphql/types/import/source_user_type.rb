# frozen_string_literal: true

module Types
  module Import
    class SourceUserType < BaseObject
      graphql_name 'ImportSourceUser'

      authorize :admin_import_source_user

      field :id,
        Types::GlobalIDType[::Import::SourceUser],
        null: false,
        description: 'Global ID of the mapping of a user on source instance to a user on destination instance.'

      field :placeholder_user,
        Types::UserType,
        null: true,
        description: 'Placeholder user associated with the import source user.'

      field :reassign_to_user,
        Types::UserType,
        null: true,
        description: 'User that contributions are reassigned to.'

      field :reassigned_by_user,
        Types::UserType,
        null: true,
        description: 'User that did the reassignment.'

      # rubocop:disable GraphQL/ExtractType -- no need to extract allowed types into a separate field
      field :source_user_identifier,
        GraphQL::Types::String,
        null: false,
        description: 'ID of the user in the source instance.'

      field :source_username,
        GraphQL::Types::String,
        null: true,
        description: 'Username of user in the source instance.'

      field :source_name,
        GraphQL::Types::String,
        null: true,
        description: 'Name of user in the source instance.'

      field :source_hostname,
        GraphQL::Types::String,
        null: false,
        description: 'Source instance hostname.'
      # rubocop:enable GraphQL/ExtractType

      field :import_type,
        Types::Import::ImportSourceEnum,
        null: false,
        description: 'Name of the importer.'

      field :status,
        Types::Import::SourceUserStatusEnum,
        null: false,
        description: 'Status of the mapping.'

      field :reassignment_error,
        GraphQL::Types::String,
        description: 'Error message if reassignment failed.'
    end
  end
end
