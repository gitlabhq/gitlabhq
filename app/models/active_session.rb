# frozen_string_literal: true

class ActiveSession
  include ActiveModel::Model

  SESSION_BATCH_SIZE = 200

  attr_accessor :created_at, :updated_at,
    :session_id, :ip_address,
    :browser, :os, :device_name, :device_type,
    :is_impersonated

  def current?(session)
    return false if session_id.nil? || session.id.nil?

    session_id == session.id
  end

  def human_device_type
    device_type&.titleize
  end

  def self.set(user, request)
    Gitlab::Redis::SharedState.with do |redis|
      session_id = request.session.id
      client = DeviceDetector.new(request.user_agent)
      timestamp = Time.current

      active_user_session = new(
        ip_address: request.ip,
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
      cleaned_up_lookup_entries(redis, user).map do |entry|
        # rubocop:disable Security/MarshalLoad
        Marshal.load(entry)
        # rubocop:enable Security/MarshalLoad
      end
    end
  end

  def self.destroy(user, session_id)
    Gitlab::Redis::SharedState.with do |redis|
      redis.srem(lookup_key_name(user.id), session_id)

      deleted_keys = redis.del(key_name(user.id, session_id))

      # only allow deleting the devise session if we could actually find a
      # related active session. this prevents another user from deleting
      # someone else's session.
      if deleted_keys > 0
        redis.del("#{Gitlab::Redis::SharedState::SESSION_NAMESPACE}:#{session_id}")
      end
    end
  end

  def self.cleanup(user)
    Gitlab::Redis::SharedState.with do |redis|
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

  def self.session_ids_for_user(user_id)
    Gitlab::Redis::SharedState.with do |redis|
      redis.smembers(lookup_key_name(user_id))
    end
  end

  def self.sessions_from_ids(session_ids)
    return [] if session_ids.empty?

    Gitlab::Redis::SharedState.with do |redis|
      session_keys = session_ids.map { |session_id| "#{Gitlab::Redis::SharedState::SESSION_NAMESPACE}:#{session_id}" }

      session_keys.each_slice(SESSION_BATCH_SIZE).flat_map do |session_keys_batch|
        redis.mget(session_keys_batch).compact.map do |raw_session|
          # rubocop:disable Security/MarshalLoad
          Marshal.load(raw_session)
          # rubocop:enable Security/MarshalLoad
        end
      end
    end
  end

  def self.raw_active_session_entries(session_ids, user_id)
    return [] if session_ids.empty?

    Gitlab::Redis::SharedState.with do |redis|
      entry_keys = session_ids.map { |session_id| key_name(user_id, session_id) }

      redis.mget(entry_keys)
    end
  end

  def self.cleaned_up_lookup_entries(redis, user)
    session_ids = session_ids_for_user(user.id)
    entries = raw_active_session_entries(session_ids, user.id)

    # remove expired keys.
    # only the single key entries are automatically expired by redis, the
    # lookup entries in the set need to be removed manually.
    session_ids_and_entries = session_ids.zip(entries)
    session_ids_and_entries.reject { |_session_id, entry| entry }.each do |session_id, _entry|
      redis.srem(lookup_key_name(user.id), session_id)
    end

    entries.compact
  end
end
