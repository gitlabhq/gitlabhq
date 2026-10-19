# frozen_string_literal: true

module MergeRequests
  module Callbacks
    class MergeSchedule < Issuable::Callbacks::Base
      ALLOWED_PARAMS = %i[merge_after merge_before].freeze

      def after_initialize
        effective_after = params.key?(:merge_after) ? params[:merge_after] : issuable.merge_schedule&.merge_after
        effective_before = params.key?(:merge_before) ? params[:merge_before] : issuable.merge_schedule&.merge_before

        if effective_after.present? || effective_before.present?
          merge_schedule = issuable.merge_schedule || issuable.build_merge_schedule
          merge_schedule.merge_after = effective_after
          merge_schedule.merge_before = effective_before
        elsif issuable.merge_schedule.present?
          issuable.merge_schedule.mark_for_destruction
        end
      end
    end
  end
end
