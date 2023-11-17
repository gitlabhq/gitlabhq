# frozen_string_literal: true

module ActivityPub
  module Projects
    class ReleasesSubscriptionService
      attr_reader :errors

      def initialize(project, payload)
        @project = project
        @payload = payload
        @errors = []
      end

      def execute
        raise "not implemented: abstract class, do not use directly."
      end

      private

      attr_reader :project, :payload

      def subscriber_url
        return unless payload['actor']
        return payload['actor'] if payload['actor'].is_a?(String)
        return unless payload['actor'].is_a?(Hash) && payload['actor']['id'].is_a?(String)

        payload['actor']['id']
      end

      def previous_subscription
        @previous_subscription ||= ReleasesSubscription.find_by_project_and_subscriber(project.id, subscriber_url)
      end
    end
  end
end
