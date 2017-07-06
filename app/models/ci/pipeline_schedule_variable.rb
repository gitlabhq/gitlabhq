module Ci
  class PipelineScheduleVariable < ActiveRecord::Base
    extend Ci::Model
    include HasVariable

    belongs_to :pipeline_schedule
  end
end
