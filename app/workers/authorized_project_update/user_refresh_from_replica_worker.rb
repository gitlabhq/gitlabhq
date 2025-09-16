# frozen_string_literal: true

module AuthorizedProjectUpdate
  class UserRefreshFromReplicaWorker
    include ApplicationWorker

    sidekiq_options retry: 3
    feature_category :permissions
    urgency :low
    worker_resource_boundary :cpu
    data_consistency :delayed
    queue_namespace :authorized_project_update

    idempotent!
    deduplicate :until_executing, including_scheduled: true

    def perform(user_id)
      ::Gitlab::Database::LoadBalancing::SessionMap.use_replica_if_available do
        user = User.find_by_id(user_id)

        if user && project_authorizations_needs_refresh?(user)
          enqueue_project_authorizations_refresh(user)
        end
      end
    end

    private

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
