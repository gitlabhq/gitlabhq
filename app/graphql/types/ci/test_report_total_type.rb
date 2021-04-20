# frozen_string_literal: true

module Types
  module Ci
    # rubocop: disable Graphql/AuthorizeTypes
    class TestReportTotalType < BaseObject
      graphql_name 'TestReportTotal'
      description 'Total test report statistics.'

      field :time, GraphQL::FLOAT_TYPE, null: true,
        description: 'Total duration of the tests.'

      field :count, GraphQL::INT_TYPE, null: true,
        description: 'Total number of the test cases.'

      field :success, GraphQL::INT_TYPE, null: true,
        description: 'Total number of test cases that succeeded.'

      field :failed, GraphQL::INT_TYPE, null: true,
        description: 'Total number of test cases that failed.'

      field :skipped, GraphQL::INT_TYPE, null: true,
        description: 'Total number of test cases that were skipped.'

      field :error, GraphQL::INT_TYPE, null: true,
        description: 'Total number of test cases that had an error.'

      field :suite_error, GraphQL::STRING_TYPE, null: true,
        description: 'Test suite error message.'
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
