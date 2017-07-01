module Ci
  class PipelineScheduleVariable < ActiveRecord::Base
    extend Ci::Model
    include HasVariable

    belongs_to :pipeline_schedule

    validates :key, uniqueness: { scope: :pipeline_schedule_id }, presence: { unless: :importing? }
  end
end
