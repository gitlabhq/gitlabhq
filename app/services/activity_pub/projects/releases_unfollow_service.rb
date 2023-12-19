# frozen_string_literal: true

module ActivityPub
  module Projects
    class ReleasesUnfollowService < ReleasesSubscriptionService
      def execute
        unless subscriber_url
          errors << "You need to provide an actor id for your unsubscribe activity"
          return false
        end

        return true unless previous_subscription.present?

        previous_subscription.destroy
      end
    end
  end
end
