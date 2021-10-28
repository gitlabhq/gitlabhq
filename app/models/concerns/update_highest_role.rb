# frozen_string_literal: true

module UpdateHighestRole
  extend ActiveSupport::Concern

  HIGHEST_ROLE_LEASE_TIMEOUT = 10.minutes.to_i
  HIGHEST_ROLE_JOB_DELAY = 10.minutes

  included do
    after_commit :update_highest_role
  end

  private

  # Schedule a Sidekiq job to update the highest role for a User
  #
  # The job will be called outside of a transaction in order to ensure the changes
  # to be committed before attempting to update the highest role.
  # The exlusive lease will not be released after completion to prevent multiple jobs
  # being executed during the defined timeout.
  def update_highest_role
    return unless update_highest_role?

    run_after_commit_or_now do
      lease_key = "update_highest_role:#{update_highest_role_attribute}"
      lease = Gitlab::ExclusiveLease.new(lease_key, timeout: HIGHEST_ROLE_LEASE_TIMEOUT)

      if lease.try_obtain
        UpdateHighestRoleWorker.perform_in(HIGHEST_ROLE_JOB_DELAY, update_highest_role_attribute)
      else
        # use same logging as ExclusiveLeaseGuard
        Gitlab::AppLogger.error('Cannot obtain an exclusive lease. There must be another instance already in execution.')
      end
    end
  end
end
