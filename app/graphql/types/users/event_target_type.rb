# frozen_string_literal: true

module Types
  module Users
    class EventTargetType < BaseUnion
      graphql_name 'EventTargetType'
      description 'Represents an object that can be the subject of an event.'

      possible_types Types::IssueType, Types::MilestoneType,
        Types::MergeRequestType, Types::ProjectType,
        Types::SnippetType, Types::UserType, Types::Wikis::WikiPageType,
        Types::DesignManagement::DesignType, Types::Notes::NoteType

      def self.resolve_type(object, _context)
        case object
        when Issue
          Types::IssueType
        when Milestone
          Types::MilestoneType
        when MergeRequest
          Types::MergeRequestType
        when Note
          Types::Notes::NoteType
        when Project
          Types::ProjectType
        when Snippet
          Types::SnippetType
        when User
          Types::UserType
        when WikiPage::Meta
          Types::Wikis::WikiPageType
        when ::DesignManagement::Design
          Types::DesignManagement::DesignType
        else
          raise "Unsupported event target type: #{object.class.name}"
        end
      end
    end
  end
end
