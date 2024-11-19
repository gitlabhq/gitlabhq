# frozen_string_literal: true

module Ci
  class PipelineScheduleEntity < Grape::Entity
    include RequestAwareEntity

    expose :id
    expose :description
    expose :path do |schedule|
      pipeline_schedules_path(schedule.project)
    end
  end
end
