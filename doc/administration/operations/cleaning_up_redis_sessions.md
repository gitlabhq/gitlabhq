# Cleaning up stale Redis sessions

Since version 6.2, GitLab stores web user sessions as key-value pairs in Redis.
Prior to GitLab 7.3, user sessions did not automatically expire from Redis. If
you have been running a large GitLab server (thousands of users) since before
GitLab 7.3 we recommend cleaning up stale sessions to compact the Redis
database after you upgrade to GitLab 7.3. You can also perform a cleanup while
still running GitLab 7.2 or older, but in that case new stale sessions will
start building up again after you clean up.

In GitLab versions prior to 7.3.0, the session keys in Redis are 16-byte
hexadecimal values such as '976aa289e2189b17d7ef525a6702ace9'. Starting with
GitLab 7.3.0, the keys are
prefixed with 'session:gitlab:', so they would look like
'session:gitlab:976aa289e2189b17d7ef525a6702ace9'. Below we describe how to
remove the keys in the old format.

**Note:** the instructions below must be modified in accordance with your
configuration settings if you have used the advanced Redis
settings outlined in
[Configuration Files Documentation](https://gitlab.com/gitlab-org/gitlab-ce/blob/master/config/README.md).


First we define a shell function with the proper Redis connection details.

```
rcli() {
  # This example works for Omnibus installations of GitLab 7.3 or newer. For an
  # installation from source you will have to change the socket path and the
  # path to redis-cli.
  sudo /opt/gitlab/embedded/bin/redis-cli -s /var/opt/gitlab/redis/redis.socket "$@"
}

# test the new shell function; the response should be PONG
rcli ping
```

Now we do a search to see if there are any session keys in the old format for
us to clean up.

```
# returns the number of old-format session keys in Redis
rcli keys '*' | grep '^[a-f0-9]\{32\}$' | wc -l
```

If the number is larger than zero, you can proceed to expire the keys from
Redis. If the number is zero there is nothing to clean up.

```
# Tell Redis to expire each matched key after 600 seconds.
rcli keys '*' | grep '^[a-f0-9]\{32\}$' | awk '{ print "expire", $0, 600 }' | rcli
# This will print '(integer) 1' for each key that gets expired.
```

Over the next 15 minutes (10 minutes expiry time plus 5 minutes Redis
background save interval) your Redis database will be compacted. If you are
still using GitLab 7.2, users who are not clicking around in GitLab during the
10 minute expiry window will be signed out of GitLab.
