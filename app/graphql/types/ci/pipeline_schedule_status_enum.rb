# frozen_string_literal: true

module Types
  module Ci
    class PipelineScheduleStatusEnum < BaseEnum
      graphql_name 'PipelineScheduleStatus'

      value 'ACTIVE', value: "active", description: 'Active pipeline schedules.'
      value 'INACTIVE', value: "inactive", description: 'Inactive pipeline schedules.'
    end
  end
end
