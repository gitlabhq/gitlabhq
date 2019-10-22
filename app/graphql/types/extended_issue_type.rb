# frozen_string_literal: true

module Types
  class ExtendedIssueType < IssueType
    graphql_name 'ExtendedIssue'

    authorize :read_issue
    expose_permissions Types::PermissionTypes::Issue
    present_using IssuePresenter

    field :subscribed, GraphQL::BOOLEAN_TYPE, method: :subscribed?, null: false, complexity: 5,
          description: 'Boolean flag for whether the currently logged in user is subscribed to this issue'
  end
end
