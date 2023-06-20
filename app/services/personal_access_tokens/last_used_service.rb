# frozen_string_literal: true

module PersonalAccessTokens
  class LastUsedService
    def initialize(personal_access_token)
      @personal_access_token = personal_access_token
    end

    def execute
      # Needed to avoid calling service on Oauth tokens
      return unless @personal_access_token.has_attribute?(:last_used_at)

      # We _only_ want to update last_used_at and not also updated_at (which
      # would be updated when using #touch).
      @personal_access_token.update_column(:last_used_at, Time.zone.now) if update?
    end

    private

    def update?
      return false if ::Gitlab::Database.read_only?

      last_used = @personal_access_token.last_used_at

      return true if last_used.nil?

      if Feature.enabled?(:update_personal_access_token_usage_information_every_10_minutes) &&
          last_used <= 10.minutes.ago
        return true
      end

      last_used <= 1.day.ago
    end
  end
end
