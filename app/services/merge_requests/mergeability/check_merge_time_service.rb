# frozen_string_literal: true

module MergeRequests
  module Mergeability
    class CheckMergeTimeService < CheckBaseService
      set_identifier :merge_time
      set_failure_explanation N_('The current time is outside of the scheduled merge time.')
      set_description 'Checks whether the merge is blocked due to a scheduled merge time'

      def execute
        merge_after = merge_request.merge_schedule&.merge_after
        merge_before = merge_request.merge_schedule&.merge_before
        return inactive if merge_after.nil? && merge_before.nil?

        if merge_after&.future? || merge_before&.past?
          failure
        else
          success
        end
      end

      def skip?
        params[:skip_merge_time_check].present?
      end

      def cacheable?
        false
      end
    end
  end
end
