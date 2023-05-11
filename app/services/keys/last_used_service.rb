# frozen_string_literal: true

module Keys
  class LastUsedService
    TIMEOUT = 1.day

    attr_reader :key

    # key - The Key for which to update the last used timestamp.
    def initialize(key)
      @key = key
    end

    def execute
      return unless update?

      # We _only_ want to update last_used_at and not also updated_at (which
      # would be updated when using #touch).
      key.update_column(:last_used_at, Time.zone.now)
    end

    def execute_async
      return unless update?

      ::SshKeys::UpdateLastUsedAtWorker.perform_async(key.id)
    end

    def update?
      return false if ::Gitlab::Database.read_only?

      last_used = key.last_used_at
      last_used.blank? || last_used <= TIMEOUT.ago
    end
  end
end
