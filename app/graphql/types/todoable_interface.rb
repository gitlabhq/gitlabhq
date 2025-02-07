# frozen_string_literal: true

module Types
  module TodoableInterface
    include Types::BaseInterface

    graphql_name 'Todoable'

    field :web_url,
      GraphQL::Types::String,
      null: true,
      description: 'URL of this object.'

    field :name,
      GraphQL::Types::String,
      null: true,
      description: 'Name or title of this object.'

    def self.resolve_type(object, context)
      case object
      when User
        Types::UserType
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
        Types::Repositories::CommitType
      when Project
        Types::ProjectType
      when Group
        Types::GroupType
      when Key # SSH key
        Types::KeyType
      when WikiPage::Meta
        Types::Wikis::WikiPageType
      else
        raise "Unknown GraphQL type for #{object}"
      end
    end

    def name
      object.try(:name) || object.try(:title)
    end
  end
end

Types::TodoableInterface.prepend_mod
