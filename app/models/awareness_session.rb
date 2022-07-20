# frozen_string_literal: true

# A Redis backed session store for real-time collaboration. A session is defined
# by its documents and the users that join this session. An online user can have
# two states within the session: "active" and "away".
#
# By design, session must eventually be cleaned up. If this doesn't happen
# explicitly, all keys used within the session model must have an expiry
# timestamp set.
class AwarenessSession # rubocop:disable Gitlab/NamespacedClass
  # An awareness session expires automatically after 1 hour of no activity
  SESSION_LIFETIME = 1.hour
  private_constant :SESSION_LIFETIME

  # Expire user awareness keys after some time of inactivity
  USER_LIFETIME = 1.hour
  private_constant :USER_LIFETIME

  PRESENCE_LIFETIME = 10.minutes
  private_constant :PRESENCE_LIFETIME

  KEY_NAMESPACE = "gitlab:awareness"
  private_constant :KEY_NAMESPACE

  class << self
    def for(value = nil)
      # Creates a unique value for situations where we have no unique value to
      # create a session with. This could be when creating a new issue, a new
      # merge request, etc.
      value = SecureRandom.uuid unless value.present?

      # We use SHA-256 based session identifiers (similar to abbreviated git
      # hashes). There is always a chance for Hash collisions (birthday
      # problem), we therefore have to pick a good tradeoff between the amount
      # of data stored and the probability of a collision.
      #
      # The approximate probability for a collision can be calculated:
      #
      # p ~= n^2 / 2m
      #   ~= (2^18)^2 / (2 * 16^15)
      #   ~= 2^36 / 2^61
      #
      # n is the number of awareness sessions and m the number of possibilities
      # for each item. For a hex number, this is 16^c, where c is the number of
      # characters. With 260k (~2^18) sessions, the probability for a collision
      # is ~2^-25.
      #
      # The number of 15 is selected carefully. The integer representation fits
      # nicely into a signed 64 bit integer and eventually allows Redis to
      # optimize its memory usage. 16 chars would exceed the space for
      # this datatype.
      id = Digest::SHA256.hexdigest(value.to_s)[0, 15]

      AwarenessSession.new(id)
    end
  end

  def initialize(id)
    @id = id
  end

  def join(user)
    user_key = user_sessions_key(user.id)

    with_redis do |redis|
      redis.pipelined do |pipeline|
        pipeline.sadd(user_key, id_i)
        pipeline.expire(user_key, USER_LIFETIME.to_i)

        pipeline.zadd(users_key, timestamp.to_f, user.id)

        # We also mark for expiry when a session key is created (first user joins),
        # because some users might never actively leave a session and the key could
        # therefore become stale, w/o us noticing.
        reset_session_expiry(pipeline)
      end
    end

    nil
  end

  def leave(user)
    user_key = user_sessions_key(user.id)

    with_redis do |redis|
      redis.pipelined do |pipeline|
        pipeline.srem(user_key, id_i)
        pipeline.zrem(users_key, user.id)
      end

      # cleanup orphan sessions and users
      #
      # this needs to be a second pipeline due to the delete operations being
      # dependent on the result of the cardinality checks
      user_sessions_count, session_users_count = redis.pipelined do |pipeline|
        pipeline.scard(user_key)
        pipeline.zcard(users_key)
      end

      redis.pipelined do |pipeline|
        pipeline.del(user_key) unless user_sessions_count > 0

        unless session_users_count > 0
          pipeline.del(users_key)
          @id = nil
        end
      end
    end

    nil
  end

  def present?(user, threshold: PRESENCE_LIFETIME)
    with_redis do |redis|
      user_timestamp = redis.zscore(users_key, user.id)
      break false unless user_timestamp.present?

      timestamp - user_timestamp < threshold
    end
  end

  def away?(user, threshold: PRESENCE_LIFETIME)
    !present?(user, threshold: threshold)
  end

  # Updates the last_activity timestamp for a user in this session
  def touch!(user)
    with_redis do |redis|
      redis.pipelined do |pipeline|
        pipeline.zadd(users_key, timestamp.to_f, user.id)

        # extend the session lifetime due to user activity
        reset_session_expiry(pipeline)
      end
    end

    nil
  end

  def size
    with_redis do |redis|
      redis.zcard(users_key)
    end
  end

  def to_param
    id&.to_s
  end

  def to_s
    "awareness_session=#{id}"
  end

  def online_users_with_last_activity(threshold: PRESENCE_LIFETIME)
    users_with_last_activity.filter do |_user, last_activity|
      user_online?(last_activity, threshold: threshold)
    end
  end

  def users
    User.where(id: user_ids)
  end

  def users_with_last_activity
    # where in (x, y, [...z]) is a set and does not maintain any order, we need
    # to make sure to establish a stable order for both, the pairs returned from
    # redis and the ActiveRecord query. Using IDs in ascending order.
    user_ids, last_activities = user_ids_with_last_activity
      .sort_by(&:first)
      .transpose

    return [] if user_ids.blank?

    users = User.where(id: user_ids).order(id: :asc)
    users.zip(last_activities)
  end

  private

  attr_reader :id

  def user_online?(last_activity, threshold:)
    last_activity.to_i + threshold.to_i > Time.zone.now.to_i
  end

  # converts session id from hex to integer representation
  def id_i
    Integer(id, 16) if id.present?
  end

  def users_key
    "#{KEY_NAMESPACE}:session:#{id}:users"
  end

  def user_sessions_key(user_id)
    "#{KEY_NAMESPACE}:user:#{user_id}:sessions"
  end

  def with_redis
    Gitlab::Redis::SharedState.with do |redis|
      yield redis if block_given?
    end
  end

  def timestamp
    Time.now.to_i
  end

  def user_ids
    with_redis do |redis|
      redis.zrange(users_key, 0, -1)
    end
  end

  # Returns an array of tuples, where the first element in the tuple represents
  # the user ID and the second part the last_activity timestamp.
  def user_ids_with_last_activity
    pairs = with_redis do |redis|
      redis.zrange(users_key, 0, -1, with_scores: true)
    end

    # map data type of score (float) to Time
    pairs.map do |user_id, score|
      [user_id, Time.zone.at(score.to_i)]
    end
  end

  # We want sessions to cleanup automatically after a certain period of
  # inactivity. This sets the expiry timestamp for this session to
  # [SESSION_LIFETIME].
  def reset_session_expiry(redis)
    redis.expire(users_key, SESSION_LIFETIME)

    nil
  end
end
