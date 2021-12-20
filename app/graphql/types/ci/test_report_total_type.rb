# frozen_string_literal: true

module Types
  module Ci
    # rubocop: disable Graphql/AuthorizeTypes
    class TestReportTotalType < BaseObject
      graphql_name 'TestReportTotal'
      description 'Total test report statistics.'

      field :time, GraphQL::Types::Float, null: true,
        description: 'Total duration of the tests.'

      field :count, GraphQL::Types::Int, null: true,
        description: 'Total number of the test cases.'

      field :success, GraphQL::Types::Int, null: true,
        description: 'Total number of test cases that succeeded.'

      field :failed, GraphQL::Types::Int, null: true,
        description: 'Total number of test cases that failed.'

      field :skipped, GraphQL::Types::Int, null: true,
        description: 'Total number of test cases that were skipped.'

      field :error, GraphQL::Types::Int, null: true,
        description: 'Total number of test cases that had an error.'

      field :suite_error, GraphQL::Types::String, null: true,
        description: 'Test suite error message.'
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
