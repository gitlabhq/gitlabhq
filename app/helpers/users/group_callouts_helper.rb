# frozen_string_literal: true

module Users
  module GroupCalloutsHelper
    INVITE_MEMBERS_BANNER = 'invite_members_banner'
    APPROACHING_SEAT_COUNT_THRESHOLD = 'approaching_seat_count_threshold'

    def show_invite_banner?(group)
      Ability.allowed?(current_user, :admin_group, group) &&
        !just_created? &&
        !user_dismissed_for_group(INVITE_MEMBERS_BANNER, group) &&
        !multiple_members?(group)
    end

    private

    def user_dismissed_for_group(feature_name, group, ignore_dismissal_earlier_than = nil)
      return false unless current_user

      current_user.dismissed_callout_for_group?(
        feature_name: feature_name,
        group: group,
        ignore_dismissal_earlier_than: ignore_dismissal_earlier_than
      )
    end

    def just_created?
      flash[:notice]&.include?('successfully created')
    end

    def multiple_members?(group)
      group.member_count > 1 || group.members_with_parents.count > 1
    end
  end
end
