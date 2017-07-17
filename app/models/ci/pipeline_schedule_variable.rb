module Ci
  class PipelineScheduleVariable < ApplicationRecord
    extend Ci::Model
    include HasVariable

    belongs_to :pipeline_schedule
  end
end
