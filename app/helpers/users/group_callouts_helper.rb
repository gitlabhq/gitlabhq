# frozen_string_literal: true

module Users
  module GroupCalloutsHelper
    APPROACHING_SEAT_COUNT_THRESHOLD = 'approaching_seat_count_threshold'
    REACHED_SEAT_COUNT_THRESHOLD = 'reached_seat_count_threshold'
    OVERAGE_SEAT_COUNT_THRESHOLD = 'overage_seat_count_threshold'

    private

    def user_dismissed_for_group(feature_name, group, ignore_dismissal_earlier_than = nil)
      return false unless current_user

      current_user.dismissed_callout_for_group?(
        feature_name: feature_name,
        group: group,
        ignore_dismissal_earlier_than: ignore_dismissal_earlier_than
      )
    end
  end
end
