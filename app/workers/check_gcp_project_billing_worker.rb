class CheckGcpProjectBillingWorker
  include ApplicationWorker

  LEASE_TIMEOUT = 15.seconds.to_i

  def self.redis_shared_state_key_for(token)
    "gitlab:gcp:#{token.hash}:billing_enabled"
  end

  def perform(token)
    return unless token
    return unless try_obtain_lease_for(token)

    billing_enabled_projects = CheckGcpProjectBillingService.new.execute(token)
    Gitlab::Redis::SharedState.with do |redis|
      redis.set(self.class.redis_shared_state_key_for(token), !billing_enabled_projects.empty?)
    end
  end

  private

  def try_obtain_lease_for(token)
    Gitlab::ExclusiveLease
      .new("check_gcp_project_billing_worker:#{token.hash}", timeout: LEASE_TIMEOUT)
      .try_obtain
  end
end
