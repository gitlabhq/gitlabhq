require 'securerandom'

class CheckGcpProjectBillingWorker
  include ApplicationWorker
  include ClusterQueue

  LEASE_TIMEOUT = 3.seconds.to_i
  SESSION_KEY_TIMEOUT = 5.minutes
  BILLING_TIMEOUT = 1.hour
  BILLING_CHANGED_LABELS = { state_transition: nil }.freeze

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

  def self.get_billing_state(token)
    Gitlab::Redis::SharedState.with do |redis|
      value = redis.get(redis_shared_state_key_for(token))
      ActiveRecord::Type::Boolean.new.type_cast_from_user(value)
    end
  end

  def perform(token_key)
    return unless token_key

    token = self.class.get_session_token(token_key)
    return unless token
    return unless try_obtain_lease_for(token)

    billing_enabled_state = !ListGcpProjectsService.new.execute(token).empty?
    update_billing_change_counter(self.class.get_billing_state(token), billing_enabled_state)
    self.class.set_billing_state(token, billing_enabled_state)
  end

  private

  def self.generate_token_key
    SecureRandom.uuid
  end

  def self.get_redis_session_key(token_key)
    "gitlab:gcp:session:#{token_key}"
  end

  def self.redis_shared_state_key_for(token)
    "gitlab:gcp:#{Digest::SHA1.hexdigest(token)}:billing_enabled"
  end

  def self.set_billing_state(token, value)
    Gitlab::Redis::SharedState.with do |redis|
      redis.set(redis_shared_state_key_for(token), value, ex: BILLING_TIMEOUT)
    end
  end

  def try_obtain_lease_for(token)
    Gitlab::ExclusiveLease
      .new("check_gcp_project_billing_worker:#{token.hash}", timeout: LEASE_TIMEOUT)
      .try_obtain
  end

  def billing_changed_counter
    @billing_changed_counter ||= Gitlab::Metrics.counter(
      :gcp_billing_change_count,
      "Counts the number of times a GCP project changed billing_enabled state from false to true",
      BILLING_CHANGED_LABELS
    )
  end

  def state_transition(previous_state, current_state)
    if previous_state.nil? && !current_state
      'no_billing'
    elsif previous_state.nil? && current_state
      'with_billing'
    elsif !previous_state && current_state
      'billing_configured'
    end
  end

  def update_billing_change_counter(previous_state, current_state)
    billing_changed_counter.increment(state_transition: state_transition(previous_state, current_state))
  end
end
