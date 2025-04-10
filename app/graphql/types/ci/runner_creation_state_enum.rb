# frozen_string_literal: true

module Types
  module Ci
    class RunnerCreationStateEnum < BaseEnum
      graphql_name 'CiRunnerCreationState'

      value 'STARTED',
        description: 'Applies to a runner that has been created, but is not yet registered and running.',
        value: 'started'
      value 'FINISHED',
        description: 'Applies to a runner that has been registered and has polled for CI/CD jobs at least once.',
        value: 'finished'
    end
  end
end
