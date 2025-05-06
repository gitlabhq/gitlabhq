# frozen_string_literal: true

module Types
  module Ci
    class RunnerJobExecutionStatusEnum < BaseEnum
      graphql_name 'CiRunnerJobExecutionStatus'

      value 'IDLE',
        description: "Runner is idle.",
        value: :idle
      value 'ACTIVE',
        description: 'Runner is busy.',
        value: :active
    end
  end
end
