# frozen_string_literal: true

module Types
  module Notes
    # rubocop: disable Graphql/AuthorizeTypes
    class DeletedNoteType < BaseObject
      graphql_name 'DeletedNote'

      field :id, ::Types::GlobalIDType[::Note],
        null: false,
        description: 'ID of the deleted note.'

      field :discussion_id, ::Types::GlobalIDType[::Discussion],
        null: true,
        description: 'ID of the discussion for the deleted note.'

      field :last_discussion_note, GraphQL::Types::Boolean,
        null: true,
        description: 'Whether deleted note is the last note in the discussion.'
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
