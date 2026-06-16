# frozen_string_literal: true

module PersonalAccessTokens
  class LastUsedService
    include ExclusiveLeaseGuard
    include Gitlab::Utils::StrongMemoize

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
      return unless needs_update?

      lb = @personal_access_token.load_balancer

      try_obtain_lease do
        ip_unseen = unseen_ip?

        ::Gitlab::Database::LoadBalancing::SessionMap.current(lb).without_sticky_writes do
          update_pat_ip if last_used_ip_needs_update?
          update_timestamp if last_used_at_needs_update?
        end

        log_audit_event_for_unseen_ip if ip_unseen
      end
    end

    private

    def lease_timeout
      LEASE_TIMEOUT
    end

    def lease_key
      @lease_key ||= "pat:last_used_update_lock:#{@personal_access_token.id}"
    end

    def lease_release?
      false
    end

    def lease_taken_log_level
      :info
    end

    def needs_update?
      return false if ::Gitlab::Database.read_only?
      # No-op on frozen records: production records are never frozen,
      # so this only guards frozen shared test fixtures from a lazy write.
      return false if @personal_access_token.frozen?

      last_used_ip_needs_update? || last_used_at_needs_update?
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

    strong_memoize_attr def last_used_ip_exists?
      Authn::PersonalAccessTokenLastUsedIp
        .where(personal_access_token_id: @personal_access_token.id, ip_address: Gitlab::IpAddressState.current)
        .exists?
    end

    strong_memoize_attr def last_used_ip_needs_update?
      return false unless Gitlab::IpAddressState.current
      return true if @personal_access_token.last_used_at.nil?
      return false if last_used_ip_exists?

      @personal_access_token.last_used_at <= LAST_USED_IP_TIMEOUT.ago
    end
    # rubocop:enable CodeReuse/ActiveRecord

    strong_memoize_attr def last_used_at_needs_update?
      last_used = @personal_access_token.last_used_at

      return true if last_used.nil?

      last_used <= LAST_USED_AT_TIMEOUT.ago
    end

    def unseen_ip?
      return false unless Gitlab::IpAddressState.current
      return false if @personal_access_token.last_used_at.nil?

      !last_used_ip_exists?
    end

    def log_audit_event_for_unseen_ip
      user = @personal_access_token.user
      return unless user
      return unless Feature.enabled?(:audit_event_pat_unseen_ip, user)

      audit_context = {
        name: 'personal_access_token_used_from_unseen_ip',
        author: user,
        scope: user,
        target: user,
        message: "Personal access token was used from a previously unseen IP address: #{Gitlab::IpAddressState.current}",
        authentication_event: true,
        authentication_provider: :pat,
        organization: @personal_access_token.organization,
        additional_details: {
          pat_id: @personal_access_token.id,
          pat_name: @personal_access_token.name
        }
      }

      ::Gitlab::Audit::Auditor.audit(audit_context)
    end
  end
end
