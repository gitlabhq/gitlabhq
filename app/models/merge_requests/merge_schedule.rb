# frozen_string_literal: true

module MergeRequests
  class MergeSchedule < ApplicationRecord
    include FromUnion

    self.table_name = 'merge_request_merge_schedules'

    belongs_to :merge_request, optional: false, inverse_of: :merge_schedule

    before_validation :set_sharding_key

    validates :merge_after, presence: true
    validate :validate_time_range

    def set_sharding_key
      self.project_id = merge_request&.target_project&.id
    end

    def validate_time_range
      return unless merge_after.present? && merge_before.present?
      return if merge_after < merge_before

      errors.add(:merge_before, _('must be after the start time'))
    end
  end
end
