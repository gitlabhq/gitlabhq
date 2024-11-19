# frozen_string_literal: true

module Types
  module Ci
    class RunnerJobExecutionStatusEnum < BaseEnum
      graphql_name 'CiRunnerJobExecutionStatus'

      value 'IDLE',
        description: "Runner is idle.",
        value: :idle,
        experiment: { milestone: '15.7' }

      value 'ACTIVE',
        description: 'Runner is busy.',
        value: :active,
        experiment: { milestone: '17.2' }
    end
  end
end
