# frozen_string_literal: true

module Ci
  class PipelineScheduleVariablePolicy < BasePolicy
    delegate :pipeline_schedule
  end
end
