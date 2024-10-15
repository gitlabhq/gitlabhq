# frozen_string_literal: true

module MergeRequests
  class MergeSchedule < ApplicationRecord
    include FromUnion

    self.table_name = 'merge_request_merge_schedules'

    belongs_to :merge_request, optional: false, inverse_of: :merge_schedule

    before_validation :set_sharding_key

    def set_sharding_key
      self.project_id = merge_request&.target_project&.id
    end
  end
end
