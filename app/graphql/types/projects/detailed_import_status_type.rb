# frozen_string_literal: true

module Types
  module Projects
    class DetailedImportStatusType < BaseObject
      graphql_name 'DetailedImportStatus'
      description 'Details of the import status of a project.'

      authorize :read_project

      field :id, ::Types::GlobalIDType[::ProjectImportState],
        description: 'ID of the import state.'

      field :status, GraphQL::Types::String,
        description: 'Current status of the import.'

      field :url, GraphQL::Types::String,
        description: 'Import url.'

      field :last_error, GraphQL::Types::String,
        description: 'Last error of the import.',
        null: true,
        authorize: :read_import_error

      field :last_update_at, Types::TimeType,
        description: 'Time of the last update.'

      field :last_update_started_at, Types::TimeType,
        description: 'Time of the start of the last update.'

      field :last_successful_update_at, Types::TimeType,
        description: 'Time of the last successful update.'

      def url
        object.project.safe_import_url
      end
    end
  end
end
