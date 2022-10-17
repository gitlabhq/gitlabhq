# frozen_string_literal: true

module Types
  module TodoableInterface
    include Types::BaseInterface

    graphql_name 'Todoable'

    field :web_url, GraphQL::Types::String, null: true, description: 'URL of this object.'

    def self.resolve_type(object, context)
      case object
      when WorkItem
        Types::WorkItemType
      when Issue
        Types::IssueType
      when MergeRequest
        Types::MergeRequestType
      when ::DesignManagement::Design
        Types::DesignManagement::DesignType
      when ::AlertManagement::Alert
        Types::AlertManagement::AlertType
      when Commit
        Types::CommitType
      else
        raise "Unknown GraphQL type for #{object}"
      end
    end
  end
end

Types::TodoableInterface.prepend_mod
