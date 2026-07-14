# frozen_string_literal: true

module Types
  module Notes
    # rubocop: disable Graphql/AuthorizeTypes -- presented through NoteType, which authorizes :read_note
    class SuggestionType < BaseObject
      graphql_name 'Suggestion'

      # rubocop:disable GraphQL/ExtractType -- mirror the flat REST Suggestion entity (from_*/to_*) for parity
      field :applied, GraphQL::Types::Boolean, null: false,
        description: 'Indicates whether the suggestion has been applied.'
      field :from_content, GraphQL::Types::String, null: false,
        description: 'Original content being replaced by the suggestion.'
      field :from_line, GraphQL::Types::Int, null: false,
        description: 'First line number of the change being suggested.'
      field :id, ::Types::GlobalIDType[::Suggestion], null: false,
        description: 'ID of the suggestion.'
      field :to_content, GraphQL::Types::String, null: false,
        description: 'Content suggested as the replacement.'
      field :to_line, GraphQL::Types::Int, null: false,
        description: 'Last line number of the change being suggested.'
      # rubocop:enable GraphQL/ExtractType
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
