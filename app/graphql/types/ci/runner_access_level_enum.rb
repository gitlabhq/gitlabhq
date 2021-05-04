# frozen_string_literal: true

module Types
  module Ci
    class RunnerAccessLevelEnum < BaseEnum
      graphql_name 'CiRunnerAccessLevel'

      ::Ci::Runner.access_levels.keys.each do |type|
        value type.upcase,
              description: "A runner that is #{type.tr('_', ' ')}.",
              value: type
      end
    end
  end
end
