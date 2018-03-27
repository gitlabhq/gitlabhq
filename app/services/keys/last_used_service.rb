module Keys
  class LastUsedService
    TIMEOUT = 1.day.to_i

    attr_reader :key

    # key - The Key for which to update the last used timestamp.
    def initialize(key)
      @key = key
    end

    def execute
      # We _only_ want to update last_used_at and not also updated_at (which
      # would be updated when using #touch).
      key.update_column(:last_used_at, Time.zone.now) if update?
    end

    def update?
      return false if ::Gitlab::Database.read_only?

      last_used = key.last_used_at

      return false if last_used && (Time.zone.now - last_used) <= TIMEOUT

      !!redis_lease.try_obtain
    end

    private

    def redis_lease
      Gitlab::ExclusiveLease
        .new("key_update_last_used_at:#{key.id}", timeout: TIMEOUT)
    end
  end
end
