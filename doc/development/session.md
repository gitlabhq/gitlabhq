---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Accessing session data
---

Session data in GitLab is stored in Redis and can be accessed in a variety of ways.

During a web request, for example:

- Rails provides access to the session from within controllers through [`ActionDispatch::Session`](https://guides.rubyonrails.org/action_controller_overview.html#session).
- Outside of controllers, it is possible to access the session through `Gitlab::Session`.

Outside of a web request it is still possible to access sessions stored in Redis. For example:

- Session IDs and contents can be [looked up directly in Redis](#redis).
- Data about the UserAgent associated with the session can be accessed through `ActiveSession`.

When storing values in a session it is best to:

- Use simple primitives and avoid storing objects to avoid marshaling complications.
- Clean up after unneeded variables to keep memory usage in Redis down.

## GitLab::Session

Sometimes you might want to persist data in the session instead of another store like the database. `Gitlab::Session` lets you access this without passing the session around extensively. For example, you could access it from within a policy without having to pass the session through to each place permissions are checked from.

The session has a hash-like interface, just like when using it from a controller. There is also `NamespacedSessionStore` for storing key-value data in a hash.

```ruby
# Lookup a value stored in the current session
Gitlab::Session.current[:my_feature]

# Modify the current session stored in redis
Gitlab::Session.current[:my_feature] = value

# Store key-value data namespaced under a key
Gitlab::NamespacedSessionStore.new(:my_feature)[some_key] = value

# Set the session for a block of code, such as for tests
Gitlab::Session.with_session(my_feature: value) do
  # Code that uses Session.current[:my_feature]
end
```

## Redis

Session data can be accessed directly through Redis. This can let you check up on a browser session when debugging.

```ruby
# Get a list of sessions
session_ids = Gitlab::Redis::Sessions.with do |redis|
  redis.smembers("#{Gitlab::Redis::Sessions::USER_SESSIONS_LOOKUP_NAMESPACE}:#{user.id}")
end

# Retrieve a specific session
session_data = Gitlab::Redis::Sessions.with { |redis| redis.get("#{Gitlab::Redis::Sessions::SESSION_NAMESPACE}:#{session_id}") }
Marshal.load(session_data)
```

## Getting device information with ActiveSession

The [**Active Sessions** page on a user's profile](../user/profile/active_sessions.md) displays information about the device used to access each session. The methods used there to list sessions can also be useful for development.

```ruby
# Get list of sessions for a given user
# Includes session_id and data from the UserAgent
ActiveSession.list(user)
```
