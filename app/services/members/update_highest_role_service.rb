# frozen_string_literal: true

module Members
  class UpdateHighestRoleService < ::BaseService
    include ExclusiveLeaseGuard

    LEASE_TIMEOUT = 30.minutes.to_i

    attr_reader :user_id

    def initialize(user_id)
      @user_id = user_id
    end

    def execute
      try_obtain_lease do
        UpdateHighestRoleWorker.perform_async(user_id)
      end
    end

    private

    def lease_key
      "update_highest_role:#{user_id}"
    end

    def lease_timeout
      LEASE_TIMEOUT
    end

    # Do not release the lease before the timeout to
    # prevent multiple jobs being executed during the
    # defined timeout
    def lease_release?
      false
    end
  end
end
