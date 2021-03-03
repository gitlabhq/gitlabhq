# frozen_string_literal: true

# Backing store for GitLab session data.
#
# The raw session information is stored by the Rails session store
# (config/initializers/session_store.rb). These entries are accessible by the
# rack_key_name class method and consistute the base of the session data
# entries. All other entries in the session store can be traced back to these
# entries.
#
# After a user logs in (config/initializers/warden.rb) a further entry is made
# in Redis. This entry holds a record of the user's logged in session. These
# are accessible with the key_name(user_id, session_id) class method. These
# entries will expire. Lookups to these entries are lazilly cleaned on future
# user access.
#
# There is a reference to all sessions that belong to a specific user. A
# user may login through multiple browsers/devices and thus record multiple
# login sessions. These are accessible through the lookup_key_name(user_id)
# class method.
#
class ActiveSession
  include ActiveModel::Model

  SESSION_BATCH_SIZE = 200
  ALLOWED_NUMBER_OF_ACTIVE_SESSIONS = 100

  attr_accessor :created_at, :updated_at,
    :ip_address, :browser, :os,
    :device_name, :device_type,
    :is_impersonated, :session_id, :session_private_id

  def current?(rack_session)
    return false if session_private_id.nil? || rack_session.id.nil?

    # Rack v2.0.8+ added private_id, which uses the hash of the
    # public_id to avoid timing attacks.
    session_private_id == rack_session.id.private_id
  end

  def human_device_type
    device_type&.titleize
  end

  def self.set(user, request)
    Gitlab::Redis::SharedState.with do |redis|
      session_private_id = request.session.id.private_id
      client = DeviceDetector.new(request.user_agent)
      timestamp = Time.current

      active_user_session = new(
        ip_address: request.remote_ip,
        browser: client.name,
        os: client.os_name,
        device_name: client.device_name,
        device_type: client.device_type,
        created_at: user.current_sign_in_at || timestamp,
        updated_at: timestamp,
        session_private_id: session_private_id,
        is_impersonated: request.session[:impersonator_id].present?
      )

      redis.pipelined do
        redis.setex(
          key_name(user.id, session_private_id),
          Settings.gitlab['session_expire_delay'] * 60,
          Marshal.dump(active_user_session)
        )

        redis.sadd(
          lookup_key_name(user.id),
          session_private_id
        )
      end
    end
  end

  def self.list(user)
    Gitlab::Redis::SharedState.with do |redis|
      cleaned_up_lookup_entries(redis, user).map do |raw_session|
        load_raw_session(raw_session)
      end
    end
  end

  def self.cleanup(user)
    Gitlab::Redis::SharedState.with do |redis|
      clean_up_old_sessions(redis, user)
      cleaned_up_lookup_entries(redis, user)
    end
  end

  def self.destroy_sessions(redis, user, session_ids)
    key_names = session_ids.map { |session_id| key_name(user.id, session_id) }

    redis.srem(lookup_key_name(user.id), session_ids)

    Gitlab::Instrumentation::RedisClusterValidator.allow_cross_slot_commands do
      redis.del(key_names)
      redis.del(rack_session_keys(session_ids))
    end
  end

  def self.destroy_session(user, session_id)
    return unless session_id

    Gitlab::Redis::SharedState.with do |redis|
      destroy_sessions(redis, user, [session_id].compact)
    end
  end

  def self.destroy_all_but_current(user, current_rack_session)
    sessions = not_impersonated(user)
    sessions.reject! { |session| session.current?(current_rack_session) } if current_rack_session

    Gitlab::Redis::SharedState.with do |redis|
      session_ids = (sessions.map(&:session_id) | sessions.map(&:session_private_id)).compact
      destroy_sessions(redis, user, session_ids) if session_ids.any?
    end
  end

  def self.not_impersonated(user)
    list(user).reject(&:is_impersonated)
  end

  def self.rack_key_name(session_id)
    "#{Gitlab::Redis::SharedState::SESSION_NAMESPACE}:#{session_id}"
  end

  def self.key_name(user_id, session_id = '*')
    "#{Gitlab::Redis::SharedState::USER_SESSIONS_NAMESPACE}:#{user_id}:#{session_id}"
  end

  def self.lookup_key_name(user_id)
    "#{Gitlab::Redis::SharedState::USER_SESSIONS_LOOKUP_NAMESPACE}:#{user_id}"
  end

  def self.list_sessions(user)
    sessions_from_ids(session_ids_for_user(user.id))
  end

  # Lists the relevant session IDs for the user.
  #
  # Returns an array of strings
  def self.session_ids_for_user(user_id)
    Gitlab::Redis::SharedState.with do |redis|
      redis.smembers(lookup_key_name(user_id))
    end
  end

  # Lists the session Hash objects for the given session IDs.
  #
  # session_ids - An array of strings
  #
  # Returns an array of ActiveSession objects
  def self.sessions_from_ids(session_ids)
    return [] if session_ids.empty?

    Gitlab::Redis::SharedState.with do |redis|
      session_keys = rack_session_keys(session_ids)

      session_keys.each_slice(SESSION_BATCH_SIZE).flat_map do |session_keys_batch|
        Gitlab::Instrumentation::RedisClusterValidator.allow_cross_slot_commands do
          redis.mget(session_keys_batch).compact.map do |raw_session|
            load_raw_session(raw_session)
          end
        end
      end
    end
  end

  # Deserializes a session Hash object from Redis.
  #
  # raw_session - Raw bytes from Redis
  #
  # Returns an ActiveSession object
  def self.load_raw_session(raw_session)
    # rubocop:disable Security/MarshalLoad
    Marshal.load(raw_session)
    # rubocop:enable Security/MarshalLoad
  end

  def self.rack_session_keys(rack_session_ids)
    rack_session_ids.map { |session_id| rack_key_name(session_id)}
  end

  def self.raw_active_session_entries(redis, session_ids, user_id)
    return [] if session_ids.empty?

    entry_keys = session_ids.map { |session_id| key_name(user_id, session_id) }

    Gitlab::Instrumentation::RedisClusterValidator.allow_cross_slot_commands do
      redis.mget(entry_keys)
    end
  end

  def self.active_session_entries(session_ids, user_id, redis)
    return [] if session_ids.empty?

    entry_keys = raw_active_session_entries(redis, session_ids, user_id)

    entry_keys.compact.map do |raw_session|
      load_raw_session(raw_session)
    end
  end

  def self.clean_up_old_sessions(redis, user)
    session_ids = session_ids_for_user(user.id)

    return if session_ids.count <= ALLOWED_NUMBER_OF_ACTIVE_SESSIONS

    # remove sessions if there are more than ALLOWED_NUMBER_OF_ACTIVE_SESSIONS.
    sessions = active_session_entries(session_ids, user.id, redis)
    sessions.sort_by! {|session| session.updated_at }.reverse!
    destroyable_sessions = sessions.drop(ALLOWED_NUMBER_OF_ACTIVE_SESSIONS)
    destroyable_session_ids = destroyable_sessions.flat_map { |session| [session.session_id, session.session_private_id] }.compact
    destroy_sessions(redis, user, destroyable_session_ids) if destroyable_session_ids.any?
  end

  # Cleans up the lookup set by removing any session IDs that are no longer present.
  #
  # Returns an array of marshalled ActiveModel objects that are still active.
  def self.cleaned_up_lookup_entries(redis, user)
    session_ids = session_ids_for_user(user.id)
    entries = raw_active_session_entries(redis, session_ids, user.id)

    # remove expired keys.
    # only the single key entries are automatically expired by redis, the
    # lookup entries in the set need to be removed manually.
    session_ids_and_entries = session_ids.zip(entries)
    redis.pipelined do
      session_ids_and_entries.reject { |_session_id, entry| entry }.each do |session_id, _entry|
        redis.srem(lookup_key_name(user.id), session_id)
      end
    end

    entries.compact
  end
end
