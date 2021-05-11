# frozen_string_literal: true

module Types
  class IssuableType < BaseUnion
    graphql_name 'Issuable'
    description 'Represents an issuable.'

    possible_types Types::IssueType, Types::MergeRequestType

    def self.resolve_type(object, context)
      case object
      when Issue
        Types::IssueType
      when MergeRequest
        Types::MergeRequestType
      else
        raise 'Unsupported issuable type'
      end
    end
  end
end

Types::IssuableType.prepend_mod_with('Types::IssuableType')
