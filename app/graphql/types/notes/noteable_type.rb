# frozen_string_literal: true

module Types
  module Notes
    module NoteableType
      include Types::BaseInterface

      field :notes, Types::Notes::NoteType.connection_type, null: false, description: "All notes on this noteable"
      field :discussions, Types::Notes::DiscussionType.connection_type, null: false, description: "All discussions on this noteable"

      definition_methods do
        def resolve_type(object, context)
          case object
          when Issue
            Types::IssueType
          when MergeRequest
            Types::MergeRequestType
          when Snippet
            Types::SnippetType
          else
            raise "Unknown GraphQL type for #{object}"
          end
        end
      end
    end
  end
end

Types::Notes::NoteableType.extend_if_ee('::EE::Types::Notes::NoteableType')
