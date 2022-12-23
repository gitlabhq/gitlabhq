# frozen_string_literal: true

module Types
  module Notes
    module NoteableInterface
      include Types::BaseInterface

      field :notes, Types::Notes::NoteType.connection_type, null: false, description: "All notes on this noteable."
      field :discussions, Types::Notes::DiscussionType.connection_type, null: false, description: "All discussions on this noteable."

      def self.resolve_type(object, context)
        case object
        when Issue
          Types::IssueType
        when MergeRequest
          Types::MergeRequestType
        when Snippet
          Types::SnippetType
        when ::DesignManagement::Design
          Types::DesignManagement::DesignType
        when ::AlertManagement::Alert
          Types::AlertManagement::AlertType
        else
          raise "Unknown GraphQL type for #{object}"
        end
      end
    end
  end
end

Types::Notes::NoteableInterface.prepend_mod_with('Types::Notes::NoteableInterface')
