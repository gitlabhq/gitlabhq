# frozen_string_literal: true

module Types
  module Users
    class ActivityStreamType < BaseObject
      graphql_name 'ActivityStream'
      description 'Activity streams associated with a user'

      authorize :read_user_profile

      field :followed_users_activity,
        Types::EventType.connection_type,
        description: 'Activity from users followed by the current user.',
        experiment: { milestone: '17.10' } do
          argument :target, EventTargetEnum, default_value: EventFilter::ALL, description: "Event target."
        end

      def followed_users_activity(target: nil, last: 20)
        scope = current_user.followees
        user_events(scope, target, last)
      end

      private

      def user_events(scope, target, last)
        UserRecentEventsFinder.new(current_user, scope, EventFilter.new(target), { limit: last }).execute
      end
    end
  end
end
