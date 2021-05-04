# frozen_string_literal: true

module Types
  module Ci
    class RunnerTypeEnum < BaseEnum
      graphql_name 'CiRunnerType'

      ::Ci::Runner.runner_types.keys.each do |type|
        value type.upcase,
              description: "A runner that is #{type.tr('_', ' ')}.",
              value: type
      end
    end
  end
end
