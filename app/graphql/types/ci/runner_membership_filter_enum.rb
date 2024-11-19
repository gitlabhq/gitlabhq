# frozen_string_literal: true

module Types
  module Ci
    class RunnerMembershipFilterEnum < BaseEnum
      graphql_name 'CiRunnerMembershipFilter'
      description 'Values for filtering runners in namespaces.'

      value 'DIRECT',
        description: "Include runners that have a direct relationship.",
        value: :direct

      value 'DESCENDANTS',
        description: "Include runners that have either a direct or inherited relationship. " \
          "These runners can be specific to a project or a group.",
        value: :descendants

      value 'ALL_AVAILABLE',
        description:
                       "Include all runners. This list includes runners for all projects in the group " \
          "and subgroups, as well as for the parent groups and instance.",
        value: :all_available,
        experiment: { milestone: '15.5' }
    end
  end
end
