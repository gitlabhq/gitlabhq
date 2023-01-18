# frozen_string_literal: true

module Types
  module Notes
    class SystemNoteMetadataType < BaseObject
      graphql_name 'SystemNoteMetadata'

      authorize :read_note

      field :id, ::Types::GlobalIDType[::SystemNoteMetadata],
        null: false,
        description: 'Global ID of the specific system note metadata.'

      field :action, GraphQL::Types::String,
        null: true,
        description: 'System note metadata action.'
      field :description_version, ::Types::DescriptionVersionType,
        null: true,
        description: 'Version of the changed description.'
    end
  end
end
