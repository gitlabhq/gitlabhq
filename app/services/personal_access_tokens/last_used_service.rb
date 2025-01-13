# frozen_string_literal: true

module PersonalAccessTokens
  class LastUsedService
    include ExclusiveLeaseGuard

    LEASE_TIMEOUT = 60.seconds.to_i
    LAST_USED_IP_TIMEOUT = 1.minute
    LAST_USED_AT_TIMEOUT = 10.minutes
    NUM_IPS_TO_STORE = 5

    def initialize(personal_access_token)
      @personal_access_token = personal_access_token
    end

    def execute
      # Needed to avoid calling service on Oauth tokens
      return unless @personal_access_token.has_attribute?(:last_used_at)

      # We _only_ want to update last_used_at and not also updated_at (which
      # would be updated when using #touch).
      return if ::Gitlab::Database.read_only?

      lb = @personal_access_token.load_balancer
      try_obtain_lease do
        ::Gitlab::Database::LoadBalancing::SessionMap.current(lb).without_sticky_writes do
          update_pat_ip if last_used_ip_needs_update?
          update_timestamp if last_used_at_needs_update?
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

    def update_timestamp
      @personal_access_token.update_columns(last_used_at: Time.zone.now)
    end

    # rubocop:disable CodeReuse/ActiveRecord  -- this is specific to this service
    def update_pat_ip
      @personal_access_token.last_used_ips << Authn::PersonalAccessTokenLastUsedIp.new(
        organization: @personal_access_token.organization,
        ip_address: Gitlab::IpAddressState.current)

      ip_count = @personal_access_token.last_used_ips.where(
        personal_access_token_id: @personal_access_token.id).count

      return unless ip_count > NUM_IPS_TO_STORE

      @personal_access_token
        .last_used_ips
        .order(created_at: :asc)
        .limit(ip_count - NUM_IPS_TO_STORE)
        .delete_all
    end

    def last_used_ip_needs_update?
      return false unless Feature.enabled?(:pat_ip, @personal_access_token.user)
      return false unless Gitlab::IpAddressState.current
      return true if @personal_access_token.last_used_at.nil?

      return false if
        Authn::PersonalAccessTokenLastUsedIp
          .where(personal_access_token_id: @personal_access_token.id, ip_address: Gitlab::IpAddressState.current)
          .exists?

      @personal_access_token.last_used_at <= LAST_USED_IP_TIMEOUT.ago
    end
    # rubocop:enable CodeReuse/ActiveRecord

    def last_used_at_needs_update?
      last_used = @personal_access_token.last_used_at

      return true if last_used.nil?

      last_used <= LAST_USED_AT_TIMEOUT.ago
    end
  end
end
