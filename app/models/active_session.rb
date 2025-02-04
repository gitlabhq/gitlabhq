# frozen_string_literal: true

# Backing store for GitLab session data.
#
# The raw session information is stored by the Rails session store
# (config/initializers/session_store.rb). These entries are accessible by the
# rack_key_name class method and constitute the base of the session data
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

  ATTR_ACCESSOR_LIST = [
    :ip_address, :browser, :os,
    :device_name, :device_type,
    :is_impersonated, :session_id, :session_private_id,
    :admin_mode
  ].freeze
  ATTR_READER_LIST = [
    :created_at, :updated_at
  ].freeze

  attr_accessor(*ATTR_ACCESSOR_LIST)
  attr_reader(*ATTR_READER_LIST)

  def created_at=(time)
    @created_at = time.is_a?(String) ? Time.zone.parse(time) : time
  end

  def updated_at=(time)
    @updated_at = time.is_a?(String) ? Time.zone.parse(time) : time
  end

  def current?(rack_session)
    return false if session_private_id.nil? || rack_session.id.nil?

    # Rack v2.0.8+ added private_id, which uses the hash of the
    # public_id to avoid timing attacks.
    session_private_id == rack_session.id.private_id
  end

  def eql?(other)
    other.is_a?(self.class) && id == other.id
  end
  alias_method :==, :eql?

  def id
    session_private_id.presence || session_id
  end

  def ids
    [session_private_id, session_id].compact
  end

  def human_device_type
    device_type&.titleize
  end

  def self.set(user, request)
    Gitlab::Redis::Sessions.with do |redis|
      session_private_id = request.session.id.private_id
      client = Gitlab::SafeDeviceDetector.new(request.user_agent)
      timestamp = Time.current
      expiry = Settings.gitlab['session_expire_delay'] * 60

      active_user_session = new(
        ip_address: request.remote_ip,
        browser: client.name,
        os: client.os_name,
        device_name: client.device_name,
        device_type: client.device_type,
        created_at: user.current_sign_in_at || timestamp,
        updated_at: timestamp,
        session_private_id: session_private_id,
        is_impersonated: request.session[:impersonator_id].present?,
        admin_mode: Gitlab::Auth::CurrentUserMode.new(user, request.session).admin_mode?
      )

      Gitlab::Instrumentation::RedisClusterValidator.allow_cross_slot_commands do
        redis.pipelined do |pipeline|
          pipeline.setex(
            key_name(user.id, session_private_id),
            expiry,
            active_user_session.dump
          )

          pipeline.sadd?(
            lookup_key_name(user.id),
            session_private_id
          )
        end
      end
    end
  end

  def self.list(user)
    Gitlab::Redis::Sessions.with do |redis|
      cleaned_up_lookup_entries(redis, user).map do |raw_session|
        load_raw_session(raw_session)
      end
    end
  end

  def self.cleanup(user)
    Gitlab::Redis::Sessions.with do |redis|
      clean_up_old_sessions(redis, user)
      cleaned_up_lookup_entries(redis, user)
    end
  end

  def self.destroy_sessions(redis, user, session_ids)
    return if session_ids.empty?

    key_names = session_ids.map { |session_id| key_name(user.id, session_id) }
    key_names += session_ids.map { |session_id| key_name_v1(user.id, session_id) }

    redis.srem(lookup_key_name(user.id), session_ids)

    session_keys = rack_session_keys(session_ids)
    Gitlab::Instrumentation::RedisClusterValidator.allow_cross_slot_commands do
      if Gitlab::Redis::ClusterUtil.cluster?(redis)
        Gitlab::Redis::ClusterUtil.batch_unlink(key_names, redis)
        Gitlab::Redis::ClusterUtil.batch_unlink(session_keys, redis)
      else
        redis.del(key_names)
        redis.del(session_keys)
      end
    end
  end

  def self.destroy_session(user, session_id)
    return unless session_id

    Gitlab::Redis::Sessions.with do |redis|
      destroy_sessions(redis, user, [session_id].compact)
    end
  end

  def self.destroy_all_but_current(user, current_rack_session)
    sessions = not_impersonated(user)
    sessions.reject! { |session| session.current?(current_rack_session) } if current_rack_session

    Gitlab::Redis::Sessions.with do |redis|
      session_ids = sessions.flat_map(&:ids)
      destroy_sessions(redis, user, session_ids) if session_ids.any?
    end
  end

  private_class_method def self.not_impersonated(user)
    list(user).reject(&:is_impersonated)
  end

  private_class_method def self.rack_key_name(session_id)
    "#{Gitlab::Redis::Sessions::SESSION_NAMESPACE}:#{session_id}"
  end

  def self.key_name(user_id, session_id = '*')
    "#{Gitlab::Redis::Sessions::USER_SESSIONS_NAMESPACE}::v2:#{user_id}:#{session_id}"
  end

  # Deprecated
  def self.key_name_v1(user_id, session_id = '*')
    "#{Gitlab::Redis::Sessions::USER_SESSIONS_NAMESPACE}:#{user_id}:#{session_id}"
  end

  def self.lookup_key_name(user_id)
    "#{Gitlab::Redis::Sessions::USER_SESSIONS_LOOKUP_NAMESPACE}:#{user_id}"
  end

  def self.list_sessions(user)
    sessions_from_ids(session_ids_for_user(user.id))
  end

  # Lists the relevant session IDs for the user.
  #
  # Returns an array of strings
  def self.session_ids_for_user(user_id)
    Gitlab::Redis::Sessions.with do |redis|
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

    Gitlab::Redis::Sessions.with do |redis|
      session_keys = rack_session_keys(session_ids)

      session_keys.each_slice(SESSION_BATCH_SIZE).flat_map do |session_keys_batch|
        Gitlab::Instrumentation::RedisClusterValidator.allow_cross_slot_commands do
          raw_sessions = if Gitlab::Redis::ClusterUtil.cluster?(redis)
                           redis.with_readonly_pipeline do
                             Gitlab::Redis::ClusterUtil.batch_get(session_keys_batch, redis)
                           end
                         else
                           redis.mget(session_keys_batch)
                         end

          raw_sessions.compact.map do |raw_session|
            load_raw_session(raw_session)
          end
        end
      end
    end
  end

  def dump
    "v2:#{Gitlab::Json.dump(self)}"
  end

  # Private:

  # raw_session - Raw bytes from Redis
  #
  # Returns an instance of this class
  private_class_method def self.load_raw_session(raw_session)
    return unless raw_session

    if raw_session.start_with?('v2:')
      session_data = Gitlab::Json.parse(raw_session[3..]).symbolize_keys
      # load only known attributes
      session_data.slice!(*ATTR_ACCESSOR_LIST.union(ATTR_READER_LIST))
      new(**session_data)
    else
      # Deprecated legacy format. To be removed in 15.0
      # See: https://gitlab.com/gitlab-org/gitlab/-/issues/30516
      # Explanation of why this Marshal.load call is OK:
      # https://gitlab.com/gitlab-com/gl-security/product-security/appsec/appsec-reviews/-/issues/124#note_744576714
      # rubocop:disable Security/MarshalLoad
      session_data = Marshal.load(raw_session)
      session_data.is_a?(ActiveSupport::Cache::Entry) ? session_data.value : session_data
      # rubocop:enable Security/MarshalLoad
    end
  end

  private_class_method def self.rack_session_keys(rack_session_ids)
    rack_session_ids.map { |session_id| rack_key_name(session_id) }
  end

  private_class_method def self.raw_active_session_entries(redis, session_ids, user_id)
    return {} if session_ids.empty?

    found = Gitlab::Instrumentation::RedisClusterValidator.allow_cross_slot_commands do
      entry_keys = session_ids.map { |session_id| key_name(user_id, session_id) }
      entries = if Gitlab::Redis::ClusterUtil.cluster?(redis)
                  redis.with_readonly_pipeline do
                    Gitlab::Redis::ClusterUtil.batch_get(entry_keys, redis)
                  end
                else
                  redis.mget(entry_keys)
                end

      session_ids.zip(entries).to_h
    end

    found.compact!
    missing = session_ids - found.keys
    return found if missing.empty?

    fallbacks = Gitlab::Instrumentation::RedisClusterValidator.allow_cross_slot_commands do
      entry_keys = missing.map { |session_id| key_name_v1(user_id, session_id) }
      entries = if Gitlab::Redis::ClusterUtil.cluster?(redis)
                  redis.with_readonly_pipeline do
                    Gitlab::Redis::ClusterUtil.batch_get(entry_keys, redis)
                  end
                else
                  redis.mget(entry_keys)
                end

      missing.zip(entries).to_h
    end

    fallbacks.merge(found.compact)
  end

  private_class_method def self.active_session_entries(session_ids, user_id, redis)
    return [] if session_ids.empty?

    raw_active_session_entries(redis, session_ids, user_id)
      .values
      .compact
      .map { load_raw_session(_1) }
  end

  private_class_method def self.clean_up_old_sessions(redis, user)
    session_ids = session_ids_for_user(user.id)

    return if session_ids.count <= ALLOWED_NUMBER_OF_ACTIVE_SESSIONS

    sessions = active_session_entries(session_ids, user.id, redis)
    sessions.sort_by!(&:updated_at).reverse!

    # remove sessions if there are more than ALLOWED_NUMBER_OF_ACTIVE_SESSIONS.
    destroyable_session_ids = sessions
      .drop(ALLOWED_NUMBER_OF_ACTIVE_SESSIONS)
      .flat_map(&:ids)

    destroy_sessions(redis, user, destroyable_session_ids)
  end

  # Cleans up the lookup set by removing any session IDs that are no longer present.
  #
  # Returns an array of marshalled ActiveModel objects that are still active.
  # Records removed keys in the optional `removed` argument array.
  def self.cleaned_up_lookup_entries(redis, user, removed = [])
    lookup_key = lookup_key_name(user.id)
    session_ids = session_ids_for_user(user.id)
    session_ids_and_entries = raw_active_session_entries(redis, session_ids, user.id)

    # remove expired keys.
    # only the single key entries are automatically expired by redis, the
    # lookup entries in the set need to be removed manually.
    redis.pipelined do |pipeline|
      session_ids_and_entries.each do |session_id, entry|
        next if entry

        pipeline.srem?(lookup_key, session_id)
      end
    end

    removed.concat(session_ids_and_entries.select { |_, v| v.nil? }.keys)

    session_ids_and_entries.values.compact
  end
end

ActiveSession.prepend_mod_with('ActiveSession')
