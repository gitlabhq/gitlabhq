# frozen_string_literal: true

module Types
  module Ci
    class RunnerMembershipFilterEnum < BaseEnum
      graphql_name 'CiRunnerMembershipFilter'
      description 'Values for filtering runners in namespaces. ' \
        'The previous type name `RunnerMembershipFilter` was deprecated in 15.4.'

      value 'DIRECT',
            description: "Include runners that have a direct relationship.",
            value: :direct

      value 'DESCENDANTS',
            description: "Include runners that have either a direct or inherited relationship. " \
              "These runners can be specific to a project or a group.",
            value: :descendants
    end
  end
end
