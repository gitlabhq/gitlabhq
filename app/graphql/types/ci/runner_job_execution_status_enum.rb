# frozen_string_literal: true

module Types
  module Ci
    class RunnerJobExecutionStatusEnum < BaseEnum
      graphql_name 'CiRunnerJobExecutionStatus'

      value 'IDLE',
            description: "Runner is idle.",
            value: :idle,
            deprecated: { milestone: '15.7', reason: :alpha }

      value 'RUNNING',
            description: 'Runner is executing jobs.',
            value: :running,
            deprecated: { milestone: '15.7', reason: :alpha }
    end
  end
end
