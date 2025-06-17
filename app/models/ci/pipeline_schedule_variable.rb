# frozen_string_literal: true

module Ci
  class PipelineScheduleVariable < Ci::ApplicationRecord
    include Ci::HasVariable
    include Ci::RawVariable

    belongs_to :pipeline_schedule

    validates :key, presence: true, uniqueness: { scope: :pipeline_schedule_id }
  end
end
