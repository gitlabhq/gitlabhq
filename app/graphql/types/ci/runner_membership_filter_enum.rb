# frozen_string_literal: true

module Types
  module Ci
    class RunnerMembershipFilterEnum < BaseEnum
      graphql_name 'RunnerMembershipFilter'
      description 'Values for filtering runners in namespaces.'

      value 'DIRECT',
            description: "Include runners that have a direct relationship.",
            value: :direct

      value 'DESCENDANTS',
            description: "Include runners that have either a direct relationship or a relationship with descendants. These can be project runners or group runners (in the case where group is queried).",
            value: :descendants
    end
  end
end
