# frozen_string_literal: true

module Authz
  module UserRefreshLock
    include Gitlab::ExclusiveLeaseHelpers

    LEASE_TTL = 5.minutes
    RETRY_IN_IF_LOCKED = 20.seconds

    private

    def with_user_refresh_lock(user, &block)
      return yield unless Feature.enabled?(:lock_auth_refresh_jobs_per_user, user)

      in_lock(lock_key(user.id), ttl: LEASE_TTL, retries: 0, &block)
    end

    def lock_key(user_id)
      "project_authorizations:user_refresh:#{user_id}"
    end

    def reschedule_on_lock_contention(*job_args)
      logger.info(
        class: self.class.name,
        message: "Couldn't obtain the lock. Rescheduling the job.",
        job_args: job_args)

      self.class.deferred(0, :lock_contention).perform_in(RETRY_IN_IF_LOCKED, *job_args)
    end
  end
end
