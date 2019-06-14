# frozen_string_literal: true

module Types
  module Notes
    class DiscussionType < BaseObject
      graphql_name 'Discussion'

      authorize :read_note

      field :id, GraphQL::ID_TYPE, null: false
      field :created_at, Types::TimeType, null: false
      field :notes, Types::Notes::NoteType.connection_type, null: false, description: "All notes in the discussion"
    end
  end
end
