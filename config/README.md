# Configuration files Documentation

Note that most configuration files (`config/*.*`) committed into
[gitlab-foss](https://gitlab.com/gitlab-org/gitlab-foss) **will not be used** for
[omnibus-gitlab](https://gitlab.com/gitlab-org/omnibus-gitlab). Configuration
files committed into gitlab-foss are only used for development.

## gitlab.yml

You can find most of the GitLab configuration settings here.

## mail_room.yml

This file is actually an YML wrapped inside an ERB file to enable templated
values to be specified from `gitlab.yml`. mail_room loads this file first as
an ERB file and then loads the resulting YML as its configuration.

## resque.yml

This file is called `resque.yml` for historical reasons. We are **NOT**
using Resque at the moment. It is used to specify Redis configuration
values when a single database instance of Redis is desired.

## Advanced Redis configuration files

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

### Example URL attribute formats for GitLab Redis `.yml` configuration files
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

## Available configuration files

The Redis instances that can be configured are described in the table below. The
order of precedence for configuration is described below, where `$NAME` and
`$FALLBACK_NAME` are the upper-cased instance names from the table, and `$name`
and `$fallback_name` are the lower-cased versions:

1. The configuration file `redis.$name.yml`.
1. **If a fallback instance is available**, the configuration file
   `redis.$fallback_name.yml`.
1. The configuration file `resque.yml`.

An example configuration file for Redis is in this directory under the name
`resque.yml.example`.

| Name                | Fallback instance | Purpose                                                                                                      |
|---------------------|-------------------|--------------------------------------------------------------------------------------------------------------|
| `cache`             |                   | Volatile non-persistent data                                                                                 |
| `queues`            |                   | Background job processing queues                                                                             |
| `shared_state`      |                   | Persistent application state                                                                                 |
| `trace_chunks`      | `shared_state`    | [CI trace chunks](https://docs.gitlab.com/ee/administration/job_logs.html#incremental-logging-architecture)  |
| `rate_limiting`     | `cache`           | [Rate limiting](https://docs.gitlab.com/ee/administration/settings/user_and_ip_rate_limits.html) state      |
| `sessions`          | `shared_state`    | [Sessions](https://docs.gitlab.com/ee/development/session.html#redis)                                        |
| `repository_cache`  | `cache`           | Repository related information                                                                               |
| `db_load_balancing` | `shared_state`    | [Database Load Balancing](https://docs.gitlab.com/ee/administration/postgresql/database_load_balancing.html) |

If no configuration is found, or no URL is found in the configuration
file, the default URL used is `redis://localhost:6379` for all Redis instances.
