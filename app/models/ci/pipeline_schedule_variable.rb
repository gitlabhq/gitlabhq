# frozen_string_literal: true

module Ci
  class PipelineScheduleVariable < Ci::ApplicationRecord
    include Ci::HasVariable
    include Ci::RawVariable

    ignore_column :value, remove_with: '19.1', remove_after: '2026-05-21' # https://gitlab.com/gitlab-org/gitlab/-/work_items/592747

    belongs_to :pipeline_schedule

    validates :key, presence: true, uniqueness: { scope: :pipeline_schedule_id }
  end
end
