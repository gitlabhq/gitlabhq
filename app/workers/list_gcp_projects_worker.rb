require 'securerandom'

class ListGcpProjectsWorker
  include ApplicationWorker
  include ClusterQueue

  LEASE_TIMEOUT = 3.seconds.to_i
  SESSION_KEY_TIMEOUT = 5.minutes
  PROJECT_TIMEOUT = 1.hour
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

  def self.read_projects(token)
    Gitlab::Redis::SharedState.with do |redis|
      value = redis.get(redis_shared_state_key_for(token))
      JSON.parse(value)
    end
  end

  def perform(token_key)
    return unless token_key

    token = self.class.get_session_token(token_key)
    return unless token
    return unless try_obtain_lease_for(token)

    billing_enabled_projects = ListGcpProjectsService.new.execute(token)
    update_billing_change_counter(!self.class.read_projects(token).empty?, !billing_enabled_projects.empty?)
    self.class.store_projects(token, billing_enabled_projects.to_json)
  end

  private

  def self.generate_token_key
    SecureRandom.uuid
  end

  def self.get_redis_session_key(token_key)
    "gitlab:gcp:session:#{token_key}"
  end

  def self.redis_shared_state_key_for(token)
    "gitlab:gcp:#{Digest::SHA1.hexdigest(token)}:projects"
  end

  def self.store_projects(token, value)
    Gitlab::Redis::SharedState.with do |redis|
      redis.set(redis_shared_state_key_for(token), value, ex: PROJECT_TIMEOUT)
    end
  end

  def try_obtain_lease_for(token)
    Gitlab::ExclusiveLease
      .new("list_gcp_projects_worker:#{token.hash}", timeout: LEASE_TIMEOUT)
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
