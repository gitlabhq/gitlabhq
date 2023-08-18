# frozen_string_literal: true

module Types
  module Ci
    class PipelineScheduleVariableType < BaseObject
      graphql_name 'PipelineScheduleVariable'

      authorize :read_pipeline_schedule_variables

      implements VariableInterface
    end
  end
end
