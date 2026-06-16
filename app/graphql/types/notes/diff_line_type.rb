# frozen_string_literal: true

module Types
  module Notes
    # rubocop: disable Graphql/AuthorizeTypes -- presented through DiscussionType, which authorizes :read_note
    class DiffLineType < BaseObject
      graphql_name 'DiffLine'
      description 'A single line of a diff displayed above a diff note.'

      # Mirror the flat REST DiffLineEntity (line_code/type/old_line/new_line/
      # text/rich_text/can_receive_suggestion) for parity.
      field :can_receive_suggestion, GraphQL::Types::Boolean, null: false,
        method: :suggestible?,
        description: 'Indicates whether the line can receive a suggestion.'
      field :line_code, GraphQL::Types::String, null: true,
        description: 'Line code of the diff line.'
      field :new_line, GraphQL::Types::Int, null: true,
        description: 'Line number on the HEAD SHA.'
      field :old_line, GraphQL::Types::Int, null: true,
        description: 'Line number on the start SHA.'
      field :rich_text, GraphQL::Types::String, null: true,
        description: 'Syntax-highlighted HTML of the diff line.'
      field :text, GraphQL::Types::String, null: true,
        description: 'Raw text of the diff line, including the leading diff sign.'
      field :type, GraphQL::Types::String, null: true,
        description: "Type of the diff line, such as 'new' or 'old'. Null for unchanged context lines."

      def rich_text
        # Mirror DiffLineEntity: `rich_text` is already syntax-highlighted,
        # html-safe markup; escape the plain-text fallback when it is absent.
        ERB::Util.html_escape(object.rich_text || object.text)
      end
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
