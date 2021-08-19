# frozen_string_literal: true

module Types
  module Ci
    # rubocop: disable Graphql/AuthorizeTypes
    class TestSuiteType < BaseObject
      graphql_name 'TestSuite'
      description 'Test suite in a pipeline test report.'

      connection_type_class(Types::CountableConnectionType)

      field :name, GraphQL::Types::String, null: true,
        description: 'Name of the test suite.'

      field :total_time, GraphQL::FLOAT_TYPE, null: true,
        description: 'Total duration of the tests in the test suite.'

      field :total_count, GraphQL::Types::Int, null: true,
        description: 'Total number of the test cases in the test suite.'

      field :success_count, GraphQL::Types::Int, null: true,
        description: 'Total number of test cases that succeeded in the test suite.'

      field :failed_count, GraphQL::Types::Int, null: true,
        description: 'Total number of test cases that failed in the test suite.'

      field :skipped_count, GraphQL::Types::Int, null: true,
        description: 'Total number of test cases that were skipped in the test suite.'

      field :error_count, GraphQL::Types::Int, null: true,
        description: 'Total number of test cases that had an error.'

      field :suite_error, GraphQL::Types::String, null: true,
        description: 'Test suite error message.'

      field :test_cases, Types::Ci::TestCaseType.connection_type, null: true,
        description: 'Test cases in the test suite.'
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
