# frozen_string_literal: true

module HashedStorage
  class BaseWorker
    include ExclusiveLeaseGuard

    LEASE_TIMEOUT = 30.seconds.to_i
    LEASE_KEY_SEGMENT = 'project_migrate_hashed_storage_worker'

    protected

    def lease_key
      # we share the same lease key for both migration and rollback so they don't run simultaneously
      "#{LEASE_KEY_SEGMENT}:#{project_id}"
    end

    def lease_timeout
      LEASE_TIMEOUT
    end
  end
end
