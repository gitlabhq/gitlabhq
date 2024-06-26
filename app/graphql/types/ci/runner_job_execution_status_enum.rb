# frozen_string_literal: true

module Types
  module Ci
    class RunnerJobExecutionStatusEnum < BaseEnum
      graphql_name 'CiRunnerJobExecutionStatus'

      value 'IDLE',
        description: "Runner is idle.",
        value: :idle

      value 'RUNNING',
        description: 'Runner is executing jobs.',
        value: :running
    end
  end
end
