class CheckGcpProjectBillingWorker
  include ApplicationWorker

  def self.redis_shared_state_key_for(token)
    "gitlab:gcp:#{token}:billing_enabled"
  end

  def perform(token)
    return unless token

    billing_enabled = CheckGcpProjectBillingService.new.execute(token)
    Gitlab::Redis::SharedState.with do |redis|
      redis.set(self.class.redis_shared_state_key_for(token), billing_enabled)
    end
  end
end
