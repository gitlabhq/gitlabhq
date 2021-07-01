# frozen_string_literal: true

module AuthorizedProjectUpdate
  class UserRefreshFromReplicaWorker # rubocop:disable Scalability/IdempotentWorker
    include ApplicationWorker

    sidekiq_options retry: 3
    feature_category :authentication_and_authorization
    urgency :low
    queue_namespace :authorized_project_update

    # This job will not be deduplicated since it is marked with
    # `data_consistency :delayed` and not `idempotent!`
    # See https://gitlab.com/gitlab-org/gitlab/-/issues/325291
    deduplicate :until_executing, including_scheduled: true

    data_consistency :delayed

    def perform(user_id)
      user = User.find_by_id(user_id)
      return unless user

      if Feature.enabled?(:user_refresh_from_replica_worker_uses_replica_db)
        enqueue_project_authorizations_refresh(user) if project_authorizations_needs_refresh?(user)
      else
        use_primary_database
        user.refresh_authorized_projects(source: self.class.name)
      end
    end

    private

    def use_primary_database
      if ::Gitlab::Database::LoadBalancing.enable?
        ::Gitlab::Database::LoadBalancing::Session.current.use_primary!
      end
    end

    def project_authorizations_needs_refresh?(user)
      AuthorizedProjectUpdate::FindRecordsDueForRefreshService.new(user).needs_refresh?
    end

    def enqueue_project_authorizations_refresh(user)
      with_context(user: user, related_class: current_caller_id) do
        AuthorizedProjectUpdate::UserRefreshWithLowUrgencyWorker.perform_async(user.id)
      end
    end

    # We use this so that we can obtain the details of the original caller
    # in the enqueued `AuthorizedProjectUpdate::UserRefreshWithLowUrgencyWorker` job.
    def current_caller_id
      Gitlab::ApplicationContext.current_context_attribute('meta.caller_id').presence
    end
  end
end
