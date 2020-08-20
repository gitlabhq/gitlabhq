# frozen_string_literal: true

module API
  module Entities
    module Ci
      class PipelineScheduleDetails < PipelineSchedule
        expose :last_pipeline, using: ::API::Entities::Ci::PipelineBasic
        expose :variables, using: ::API::Entities::Ci::Variable
      end
    end
  end
end
