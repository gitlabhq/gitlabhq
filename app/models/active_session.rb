# frozen_string_literal: true

class ActiveSession
  include ActiveModel::Model

  SESSION_BATCH_SIZE = 200
  ALLOWED_NUMBER_OF_ACTIVE_SESSIONS = 100

  attr_accessor :created_at, :updated_at,
    :ip_address, :browser, :os,
    :device_name, :device_type,
    :is_impersonated, :session_id

  def current?(session)
    return false if session_id.nil? || session.id.nil?

    # Rack v2.0.8+ added private_id, which uses the hash of the
    # public_id to avoid timing attacks.
    session_id.private_id == session.id.private_id
  end

  def human_device_type
    device_type&.titleize
  end

  # This is not the same as Rack::Session::SessionId#public_id, but we
  # need to preserve this for backwards compatibility.
  def public_id
    Gitlab::CryptoHelper.aes256_gcm_encrypt(session_id.public_id)
  end

  def self.set(user, request)
    Gitlab::Redis::SharedState.with do |redis|
      session_id = request.session.id.public_id
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
        session_id: session_id,
        is_impersonated: request.session[:impersonator_id].present?
      )

      redis.pipelined do
        redis.setex(
          key_name(user.id, session_id),
          Settings.gitlab['session_expire_delay'] * 60,
          Marshal.dump(active_user_session)
        )

        redis.sadd(
          lookup_key_name(user.id),
          session_id
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

  def self.destroy(user, session_id)
    return unless session_id

    Gitlab::Redis::SharedState.with do |redis|
      destroy_sessions(redis, user, [session_id])
    end
  end

  def self.destroy_with_public_id(user, public_id)
    decrypted_id = decrypt_public_id(public_id)

    return if decrypted_id.nil?

    session_id = Rack::Session::SessionId.new(decrypted_id)
    destroy(user, session_id)
  end

  def self.destroy_sessions(redis, user, session_ids)
    key_names = session_ids.map { |session_id| key_name(user.id, session_id.public_id) }

    redis.srem(lookup_key_name(user.id), session_ids.map(&:public_id))
    redis.del(key_names)
    redis.del(rack_session_keys(session_ids))
  end

  def self.cleanup(user)
    Gitlab::Redis::SharedState.with do |redis|
      clean_up_old_sessions(redis, user)
      cleaned_up_lookup_entries(redis, user)
    end
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
  # Returns an array of Rack::Session::SessionId objects
  def self.session_ids_for_user(user_id)
    Gitlab::Redis::SharedState.with do |redis|
      session_ids = redis.smembers(lookup_key_name(user_id))
      session_ids.map { |id| Rack::Session::SessionId.new(id) }
    end
  end

  # Lists the session Hash objects for the given session IDs.
  #
  # session_ids - An array of Rack::Session::SessionId objects
  #
  # Returns an array of ActiveSession objects
  def self.sessions_from_ids(session_ids)
    return [] if session_ids.empty?

    Gitlab::Redis::SharedState.with do |redis|
      session_keys = rack_session_keys(session_ids)

      session_keys.each_slice(SESSION_BATCH_SIZE).flat_map do |session_keys_batch|
        redis.mget(session_keys_batch).compact.map do |raw_session|
          load_raw_session(raw_session)
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
    session = Marshal.load(raw_session)
    # rubocop:enable Security/MarshalLoad

    # Older ActiveSession models serialize `session_id` as strings, To
    # avoid breaking older sessions, we keep backwards compatibility
    # with older Redis keys and initiate Rack::Session::SessionId here.
    session.session_id = Rack::Session::SessionId.new(session.session_id) if session.try(:session_id).is_a?(String)
    session
  end

  def self.rack_session_keys(session_ids)
    session_ids.each_with_object([]) do |session_id, arr|
      # This is a redis-rack implementation detail
      # (https://github.com/redis-store/redis-rack/blob/master/lib/rack/session/redis.rb#L88)
      #
      # We need to delete session keys based on the legacy public key name
      # and the newer private ID keys, but there's no well-defined interface
      # so we have to do it directly.
      arr << "#{Gitlab::Redis::SharedState::SESSION_NAMESPACE}:#{session_id.public_id}"
      arr << "#{Gitlab::Redis::SharedState::SESSION_NAMESPACE}:#{session_id.private_id}"
    end
  end

  def self.raw_active_session_entries(redis, session_ids, user_id)
    return [] if session_ids.empty?

    entry_keys = session_ids.map { |session_id| key_name(user_id, session_id) }

    redis.mget(entry_keys)
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
    destroyable_session_ids = destroyable_sessions.map { |session| session.session_id }
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

  private_class_method def self.decrypt_public_id(public_id)
    Gitlab::CryptoHelper.aes256_gcm_decrypt(public_id)
  rescue
    nil
  end
end
