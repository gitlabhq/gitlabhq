# frozen_string_literal: true

module Resolvers
  module Users
    class ContributionCalendarResolver < BaseResolver
      type Types::Users::ContributionCalendarType, null: true

      description 'Contribution calendar of the user, as the profile page shows it.'

      alias_method :target_user, :object

      # Null, not an error, for a profile the viewer may not read (private,
      # blocked, unconfirmed): the same gate as the calendar controller's
      # `authorize_read_user_profile!`.
      def resolve
        return unless Ability.allowed?(current_user, :read_user_profile, target_user)

        ::Gitlab::ContributionsCalendar.new(target_user, current_user)
      end
    end
  end
end
