# frozen_string_literal: true

module AuthorizedProjectUpdate
  class UserRefreshOverUserRangeWorker
    # This worker checks if users requires an update to their project_authorizations records.
    # This check is done via the data read from the database replica (and not from the primary).
    # If this check returns true, a completely new Sidekiq job is enqueued for a specific user
    # so as to update its project_authorizations records.

    # There is a possibility that the data in the replica is lagging behind the primary
    # and hence it becomes very important that we check if an update is indeed required for this user
    # once again via the primary database, which is the reason why we enqueue a completely new Sidekiq job
    # via `UserRefreshWithLowUrgencyWorker` for this user.

    include ApplicationWorker

    sidekiq_options retry: 3

    feature_category :permissions
    urgency :low
    queue_namespace :authorized_project_update

    data_consistency :delayed
    idempotent!

    def perform(start_user_id, end_user_id)
      User.where(id: start_user_id..end_user_id).find_each do |user| # rubocop: disable CodeReuse/ActiveRecord
        enqueue_project_authorizations_refresh(user) if project_authorizations_needs_refresh?(user)
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
