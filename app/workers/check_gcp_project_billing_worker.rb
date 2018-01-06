require 'securerandom'

class CheckGcpProjectBillingWorker
  include ApplicationWorker
  include ClusterQueue

  LEASE_TIMEOUT = 15.seconds.to_i

  def self.generate_redis_token_key
    SecureRandom.uuid
  end

  def self.redis_shared_state_key_for(token)
    "gitlab:gcp:#{token.hash}:billing_enabled"
  end

  def perform(token_key)
    return unless token_key

    token = get_token(token_key)
    return unless token
    return unless try_obtain_lease_for(token)

    billing_enabled_projects = CheckGcpProjectBillingService.new.execute(token)
    Gitlab::Redis::SharedState.with do |redis|
      redis.set(self.class.redis_shared_state_key_for(token), !billing_enabled_projects.empty?)
    end
  end

  private

  def get_token(token_key)
    Gitlab::Redis::SharedState.with { |redis| redis.get(token_key) }
  end

  def try_obtain_lease_for(token)
    Gitlab::ExclusiveLease
      .new("check_gcp_project_billing_worker:#{token.hash}", timeout: LEASE_TIMEOUT)
      .try_obtain
  end
end
