require 'securerandom'

class CheckGcpProjectBillingWorker
  include ApplicationWorker
  include ClusterQueue

  LEASE_TIMEOUT = 15.seconds.to_i
  SESSION_KEY_TIMEOUT = 5.minutes
  BILLING_TIMEOUT = 1.hour

  def self.get_session_token(token_key)
    Gitlab::Redis::SharedState.with do |redis|
      redis.get(get_redis_session_key(token_key))
    end
  end

  def self.store_session_token(token)
    generate_token_key.tap do |token_key|
      Gitlab::Redis::SharedState.with do |redis|
        redis.set(get_redis_session_key(token_key), token, ex: SESSION_KEY_TIMEOUT)
      end
    end
  end

  def self.redis_shared_state_key_for(token)
    "gitlab:gcp:#{token.hash}:billing_enabled"
  end

  def perform(token_key)
    return unless token_key

    token = self.get_session_token(token_key)
    return unless token
    return unless try_obtain_lease_for(token)

    billing_enabled_projects = CheckGcpProjectBillingService.new.execute(token)
    Gitlab::Redis::SharedState.with do |redis|
      redis.set(self.class.redis_shared_state_key_for(token),
        !billing_enabled_projects.empty?,
        ex: BILLING_TIMEOUT)
    end
  end

  private

  def self.generate_token_key
    SecureRandom.uuid
  end

  def self.get_redis_session_key(token_key)
    "gitlab:gcp:session:#{token_key}"
  end

  def try_obtain_lease_for(token)
    Gitlab::ExclusiveLease
      .new("check_gcp_project_billing_worker:#{token.hash}", timeout: LEASE_TIMEOUT)
      .try_obtain
  end
end
