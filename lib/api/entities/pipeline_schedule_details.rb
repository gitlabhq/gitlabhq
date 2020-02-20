# frozen_string_literal: true

module API
  module Entities
    class PipelineScheduleDetails < Entities::PipelineSchedule
      expose :last_pipeline, using: Entities::PipelineBasic
      expose :variables, using: Entities::Variable
    end
  end
end
