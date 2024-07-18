# frozen_string_literal: true

module PersonalAccessTokens
  class LastUsedService
    include ExclusiveLeaseGuard

    LEASE_TIMEOUT = 60.seconds.to_i

    def initialize(personal_access_token)
      @personal_access_token = personal_access_token
    end

    def execute
      # Needed to avoid calling service on Oauth tokens
      return unless @personal_access_token.has_attribute?(:last_used_at)

      # We _only_ want to update last_used_at and not also updated_at (which
      # would be updated when using #touch).
      return unless update?

      with_lease do
        ::Gitlab::Database::LoadBalancing::Session.without_sticky_writes do
          @personal_access_token.update_column(:last_used_at, Time.zone.now)
        end
      end
    end

    private

    def lease_timeout
      LEASE_TIMEOUT
    end

    def lease_key
      @lease_key ||= "pat:last_used_update_lock:#{@personal_access_token.id}"
    end

    def with_lease
      return yield unless Feature.enabled?(
        :use_lease_for_pat_last_used_update,
        Feature.current_request,
        type: :gitlab_com_derisk
      )

      try_obtain_lease do
        yield
      end
    end

    def update?
      return false if ::Gitlab::Database.read_only?

      last_used = @personal_access_token.last_used_at

      return true if last_used.nil?

      last_used <= 10.minutes.ago
    end
  end
end
