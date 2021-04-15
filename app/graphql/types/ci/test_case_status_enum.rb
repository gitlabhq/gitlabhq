# frozen_string_literal: true

module Types
  module Ci
    class TestCaseStatusEnum < BaseEnum
      graphql_name 'TestCaseStatus'

      ::Gitlab::Ci::Reports::TestCase::STATUS_TYPES.each do |status|
        value status,
              description: "Test case that has a status of #{status}.",
              value: status
      end
    end
  end
end
