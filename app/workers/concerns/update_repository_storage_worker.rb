# frozen_string_literal: true

module UpdateRepositoryStorageWorker
  extend ActiveSupport::Concern
  include ApplicationWorker

  included do
    deduplicate :until_executed
    idempotent!
    feature_category :gitaly
    urgency :throttled
  end

  LEASE_TIMEOUT = 30.minutes.to_i

  def perform(repository_storage_move_id)
    repository_storage_move = find_repository_storage_move(repository_storage_move_id)

    container_id = repository_storage_move.container_id

    # Use exclusive lock to prevent multiple storage migrations at the same time
    #
    # Note: instead of using a randomly generated `uuid`, we provide a worker jid value.
    # That will allow to track a worker that requested a lease.
    lease_key = [self.class.name.underscore, container_id].join(':')
    exclusive_lease = Gitlab::ExclusiveLease.new(lease_key, uuid: jid, timeout: LEASE_TIMEOUT)
    lease = exclusive_lease.try_obtain

    if lease
      begin
        update_repository_storage(repository_storage_move)
      ensure
        exclusive_lease.cancel
      end
    else
      # If there is an ongoing storage migration, then the current one should be marked as failed
      repository_storage_move.do_fail!

      # A special case
      # Sidekiq can receive an interrupt signal during the processing.
      # It kills existing workers and reschedules their jobs using the same jid.
      # But it can cause a situation when the migration is only half complete (see https://gitlab.com/gitlab-org/gitlab/-/issues/429049#note_1635650597)
      #
      # Here we detect this case and release the lock.
      uuid = Gitlab::ExclusiveLease.get_uuid(lease_key)
      exclusive_lease.cancel if uuid == jid
    end
  end

  private

  def find_repository_storage_move(repository_storage_move_id)
    raise NotImplementedError
  end

  def update_repository_storage(repository_storage_move)
    raise NotImplementedError
  end
end
