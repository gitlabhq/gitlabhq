# frozen_string_literal: true

module AuthorizedProjectUpdate
  class UserRefreshFromReplicaWorker
    include ApplicationWorker

    sidekiq_options retry: 3
    feature_category :permissions
    urgency :low
    data_consistency :delayed, feature_flag: :change_data_consistency_for_permissions_workers
    queue_namespace :authorized_project_update

    idempotent!
    deduplicate :until_executing, including_scheduled: true

    def perform(user_id)
      use_replica_if_available do
        user = User.find_by_id(user_id)

        if user && project_authorizations_needs_refresh?(user)
          enqueue_project_authorizations_refresh(user)
        end
      end
    end

    private

    def use_replica_if_available(&block)
      ::Gitlab::Database::LoadBalancing::SessionMap
        .with_sessions([::ApplicationRecord, ::Ci::ApplicationRecord])
        .use_replicas_for_read_queries(&block)
    end

    def project_authorizations_needs_refresh?(user)
      AuthorizedProjectUpdate::FindRecordsDueForRefreshService.new(user).needs_refresh?
    end

    def enqueue_project_authorizations_refresh(user)
      with_context(user: user) do
        AuthorizedProjectUpdate::UserRefreshWithLowUrgencyWorker.perform_async(user.id)
      end
    end
  end
end
