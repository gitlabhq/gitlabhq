# frozen_string_literal: true

module MergeRequests
  class UpdateMergeScheduleService
    def initialize(merge_request, merge_after:)
      @merge_request = merge_request
      @merge_after = merge_after
    end

    def execute
      if merge_after.present?
        merge_schedule = merge_request.merge_schedule || merge_request.build_merge_schedule
        merge_schedule.merge_after = merge_after
        merge_request.merge_schedule = merge_schedule
      elsif merge_request.merge_schedule.present?
        merge_request.merge_schedule.destroy!
      end
    end

    private

    attr_reader :merge_request, :merge_after
  end
end
