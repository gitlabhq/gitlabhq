# frozen_string_literal: true

module Types
  module Ci
    # rubocop: disable Graphql/AuthorizeTypes
    class TestCaseType < BaseObject
      graphql_name 'TestCase'
      description 'Test case in pipeline test report.'

      connection_type_class Types::CountableConnectionType

      field :status,
        Types::Ci::TestCaseStatusEnum,
        null: true,
        description: "Status of the test case (#{::Gitlab::Ci::Reports::TestCase::STATUS_TYPES.join(', ')})."

      field :name, GraphQL::Types::String, null: true,
        description: 'Name of the test case.'

      field :classname, GraphQL::Types::String, null: true,
        description: 'Classname of the test case.'

      field :execution_time, GraphQL::Types::Float, null: true,
        description: 'Test case execution time in seconds.'

      field :file, GraphQL::Types::String, null: true,
        description: 'Path to the file of the test case.'

      field :attachment_url, GraphQL::Types::String, null: true,
        description: 'URL of the test case attachment file.'

      field :system_output, GraphQL::Types::String, null: true,
        description: 'System output of the test case.'

      field :stack_trace, GraphQL::Types::String, null: true,
        description: 'Stack trace of the test case.'

      field :recent_failures,
        Types::Ci::RecentFailuresType,
        null: true,
        description: 'Recent failure history of the test case on the base branch.'
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
