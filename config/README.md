# Configuration files Documentation

Note that most configuration files (`config/*.*`) committed into
[gitlab-ce](https://gitlab.com/gitlab-org/gitlab-ce) **will not be used** for
[omnibus-gitlab](https://gitlab.com/gitlab-org/omnibus-gitlab). Configuration
files committed into gitlab-ce are only used for development.

## gitlab.yml

You can find most of GitLab configuration settings here.

## mail_room.yml

This file is actually an YML wrapped inside an ERB file to enable templated
values to be specified from `gitlab.yml`. mail_room loads this file first as
an ERB file and then loads the resulting YML as its configuration.

## resque.yml

This file is called `resque.yml` for historical reasons. We are **NOT**
using Resque at the moment. It is used to specify Redis configuration
values when a single database instance of Redis is desired.

# Advanced Redis configuration files

In more advanced configurations of Redis key-value storage, it is desirable
to separate the keys by lifecycle and intended use to ease provisioning and
management of scalable Redis clusters.

These settings provide routing and other configuration data (such as sentinel,
persistence policies, and other Redis customization) for connections
to Redis single instances, Redis sentinel, and Redis clusters.

If desired, the routing URL provided by these settings can be used with:
1. Unix Socket
    1. named socket for each Redis instance desired.
    2. `database number` for each Redis instance desired.
2. TCP Socket
    1. `host name` or IP for each Redis instance desired
    2. TCP port number for each Redis instance desired
    3. `database number` for each Redis instance desired
    
## Example URL attribute formats for GitLab Redis `.yml` configuration files
* Unix Socket, default Redis database (0)
    * `url: unix:/path/to/redis.sock`
    * `url: unix:/path/to/redis.sock?db=`
* Unix Socket, Redis database 44
    * `url: unix:/path/to/redis.sock?db=44`
    * `url: unix:/path/to/redis.sock?extra=foo&db=44`
* TCP Socket for Redis on localhost, port 6379, database 33
    * `url: redis://:mynewpassword@localhost:6379/33`
* TCP Socket for Redis on remote host `myserver`, port 6379, database 33
    * `url: redis://:mynewpassword@myserver:6379/33`

## redis.cache.yml

If configured, `redis.cache.yml` overrides the
`resque.yml` settings to configure the Redis database instance
used for `Rails.cache` and other volatile non-persistent data which enhances
the performance of GitLab.
Settings here can be overridden by the environment variable
`GITLAB_REDIS_CACHE_CONFIG_FILE` which provides
an alternate location for configuration settings.

The order of precedence for the URL used to connect to the Redis instance
used for `cache` is:
1. URL from a configuration file pointed to by the
`GITLAB_REDIS_CACHE_CONFIG_FILE` environment variable
2. URL from `redis.cache.yml`
3. URL from a configuration file pointed to by the
`GITLAB_REDIS_CONFIG_FILE` environment variable
4. URL from `resque.yml`
5. `redis://localhost:6380`

The order of precedence for all other configuration settings for `cache`
are selected from only the first of the following files found (if a setting
is not provided in an earlier file, the remainder of the files are not
searched):
1. the configuration file pointed to by the
`GITLAB_REDIS_CACHE_CONFIG_FILE` environment variable
2. the configuration file `redis.cache.yml`
3. the configuration file pointed to by the
`GITLAB_REDIS_CONFIG_FILE` environment variable
4. the configuration file `resque.yml`

## redis.queues.yml

If configured, `redis.queues.yml` overrides the
`resque.yml` settings to configure the Redis database instance
used for clients of `::Gitlab::Redis::Queues`.
These queues are intended to be the foundation
of reliable inter-process communication between modules, whether on the same
host node, or within a cluster.   The primary clients of the queues are
SideKiq, Mailroom, CI Runner, Workhorse, and push services.  Settings here can
be overridden by the environment variable
`GITLAB_REDIS_QUEUES_CONFIG_FILE` which provides an alternate location for
configuration settings.

The order of precedence for the URL used to connect to the Redis instance
used for `queues` is:
1. URL from a configuration file pointed to by the
`GITLAB_REDIS_QUEUES_CONFIG_FILE` environment variable
2. URL from `redis.queues.yml`
3. URL from a configuration file pointed to by the
`GITLAB_REDIS_CONFIG_FILE` environment variable
4. URL from `resque.yml`
5. `redis://localhost:6381`

The order of precedence for all other configuration settings for `queues`
are selected from only the first of the following files found (if a setting
is not provided in an earlier file, the remainder of the files are not
searched):
1. the configuration file pointed to by the
`GITLAB_REDIS_QUEUES_CONFIG_FILE` environment variable
2. the configuration file `redis.queues.yml`
3. the configuration file pointed to by the
`GITLAB_REDIS_CONFIG_FILE` environment variable
4. the configuration file `resque.yml`

## redis.shared_state.yml

If configured, `redis.shared_state.yml` overrides the
`resque.yml` settings to configure the Redis database instance
used for clients of `::Gitlab::Redis::SharedState` such as session state,
and rate limiting.
Settings here can be overridden by the environment variable
`GITLAB_REDIS_SHARED_STATE_CONFIG_FILE` which provides
an alternate location for configuration settings.

The order of precedence for the URL used to connect to the Redis instance
used for `shared_state` is:
1. URL from a configuration file pointed to by the
`GITLAB_REDIS_SHARED_STATE_CONFIG_FILE` environment variable
2. URL from `redis.shared_state.yml`
3. URL from a configuration file pointed to by the
`GITLAB_REDIS_CONFIG_FILE` environment variable
4. URL from `resque.yml`
5. `redis://localhost:6382`

The order of precedence for all other configuration settings for `shared_state`
are selected from only the first of the following files found (if a setting
is not provided in an earlier file, the remainder of the files are not
searched):
1. the configuration file pointed to by the
`GITLAB_REDIS_SHARED_STATE_CONFIG_FILE` environment variable
2. the configuration file `redis.shared_state.yml`
3. the configuration file pointed to by the
`GITLAB_REDIS_CONFIG_FILE` environment variable
4. the configuration file `resque.yml`

