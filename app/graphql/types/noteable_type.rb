# frozen_string_literal: true

module Types
  class NoteableType < BaseUnion
    graphql_name 'NoteableType'
    description 'Represents an object that supports notes.'

    possible_types Types::IssueType, Types::DesignManagement::DesignType, Types::MergeRequestType

    def self.resolve_type(object, context)
      case object
      when Issue
        Types::IssueType
      when ::DesignManagement::Design
        Types::DesignManagement::DesignType
      when MergeRequest
        Types::MergeRequestType
      else
        raise 'Unsupported issuable type'
      end
    end
  end
end
