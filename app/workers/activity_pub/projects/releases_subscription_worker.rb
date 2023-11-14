# frozen_string_literal: true

module ActivityPub
  module Projects
    class ReleasesSubscriptionWorker
      include ApplicationWorker
      include Gitlab::Routing.url_helpers

      idempotent!
      worker_has_external_dependencies!
      feature_category :release_orchestration
      data_consistency :delayed
      queue_namespace :activity_pub

      sidekiq_retries_exhausted do |msg, _ex|
        subscription_id = msg['args'].second
        subscription = ActivityPub::ReleasesSubscription.find_by_id(subscription_id)
        subscription&.destroy
      end

      def perform(subscription_id)
        subscription = ActivityPub::ReleasesSubscription.find_by_id(subscription_id)
        return if subscription.nil?

        unless subscription.project.public?
          subscription.destroy
          return
        end

        InboxResolverService.new(subscription).execute if needs_resolving?(subscription)
        AcceptFollowService.new(subscription, project_releases_url(subscription.project)).execute
      end

      def needs_resolving?(subscription)
        subscription.subscriber_inbox_url.blank? || subscription.shared_inbox_url.blank?
      end
    end
  end
end
