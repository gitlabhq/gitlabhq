# frozen_string_literal: true

module Types
  module Ci
    class RunnerTypeEnum < BaseEnum
      graphql_name 'CiRunnerType'

      ::Ci::Runner::AVAILABLE_TYPES.each do |runner_type|
        value runner_type.upcase,
              description: "A runner that is #{runner_type.tr('_', ' ')}.",
              value: runner_type
      end
    end
  end
end
