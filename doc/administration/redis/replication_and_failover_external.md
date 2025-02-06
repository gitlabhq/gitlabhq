---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Redis replication and failover providing your own instance
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

If you're hosting GitLab on a cloud provider, you can optionally use a managed
service for Redis. For example, AWS offers ElastiCache that runs Redis.

Alternatively, you may opt to manage your own Redis instance separate from the
Linux package.

## Requirements

The following are the requirements for providing your own Redis instance:

- Find the minimum Redis version that is required in the
  [requirements page](../../install/requirements.md).
- Standalone Redis or Redis high availability with Sentinel are supported. Redis
  Cluster is not supported.
- Managed Redis from cloud providers such as AWS ElastiCache works fine. If these
  services support high availability, be sure it is **not** the Redis Cluster type.

Note the Redis node's IP address or hostname, port, and password (if required).

## Redis as a managed service in a cloud provider

1. Set up Redis according to the [requirements](#requirements).
1. Configure the GitLab application servers with the appropriate connection details
   for your external Redis service in your `/etc/gitlab/gitlab.rb` file:

   When using a single Redis instance:

   ```ruby
   redis['enable'] = false

   gitlab_rails['redis_host'] = '<redis_instance_url>'
   gitlab_rails['redis_port'] = '<redis_instance_port>'

   # Required if Redis authentication is configured on the Redis node
   gitlab_rails['redis_password'] = '<redis_password>'

   # Set to true if instance is using Redis SSL 
   gitlab_rails['redis_ssl'] = true
   ```

   When using separate Redis Cache and Persistent instances:

   ```ruby
   redis['enable'] = false

   # Default Redis connection
   gitlab_rails['redis_host'] = '<redis_persistent_instance_url>'
   gitlab_rails['redis_port'] = '<redis_persistent_instance_port>'
   gitlab_rails['redis_password'] = '<redis_persistent_password>'

   # Set to true if instance is using Redis SSL
   gitlab_rails['redis_ssl'] = true

   # Redis Cache connection
   # Replace `redis://` with `rediss://` if using SSL
   gitlab_rails['redis_cache_instance'] = 'redis://:<redis_cache_password>@<redis_cache_instance_url>:<redis_cache_instance_port>'
   ```

1. Reconfigure for the changes to take effect:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

### Setting the eviction policy

When running a single Redis instance the eviction policy should be set to `noeviction`.

If you are running separate Redis Cache and Persistent instances, Cache should be configured as a [Least Recently Used cache](https://redis.io/docs/latest/operate/rs/databases/memory-performance/eviction-policy/) (LRU) with `allkeys-lru` while Persistent should be set to `noeviction`.

Configuring this depends on the cloud provider or service, but generally the following settings and values configure a cache:

- `maxmemory-policy` = `allkeys-lru`
- `maxmemory-samples` = `5`

## Redis replication and failover with your own Redis servers

This is the documentation for configuring a scalable Redis setup when
you have installed Redis all by yourself and not using the bundled one that
comes with the Linux packages, although using the Linux packages is
highly recommend as we optimize them specifically for GitLab, and we take
care of upgrading Redis to the latest supported version.

Note also that you may elect to override all references to
`/home/git/gitlab/config/resque.yml` in accordance with the advanced Redis
settings outlined in
[Configuration Files Documentation](https://gitlab.com/gitlab-org/gitlab/-/blob/master/config/README.md).

We cannot stress enough the importance of reading the
[replication and failover](replication_and_failover.md) documentation of the
Linux package Redis HA because it provides some invaluable information to the configuration
of Redis. Read it before going forward with this guide.

Before proceeding on setting up the new Redis instances, here are some
requirements:

- All Redis servers in this guide must be configured to use a TCP connection
  instead of a socket. To configure Redis to use TCP connections you need to
  define both `bind` and `port` in the Redis configuration file. You can bind to all
  interfaces (`0.0.0.0`) or specify the IP of the desired interface
  (for example, one from an internal network).
- Since Redis 3.2, you must define a password to receive external connections
  (`requirepass`).
- If you are using Redis with Sentinel, you also need to define the same
  password for the replica password definition (`masterauth`) in the same instance.

In addition, read the prerequisites as described in
[Redis replication and failover with the Linux package](replication_and_failover.md#requirements).

### Step 1. Configuring the primary Redis instance

Assuming that the Redis primary instance IP is `10.0.0.1`:

1. [Install Redis](../../install/installation.md#8-redis).
1. Edit `/etc/redis/redis.conf`:

   ```conf
   ## Define a `bind` address pointing to a local IP that your other machines
   ## can reach you. If you really need to bind to an external accessible IP, make
   ## sure you add extra firewall rules to prevent unauthorized access:
   bind 10.0.0.1

   ## Define a `port` to force redis to listen on TCP so other machines can
   ## connect to it (default port is `6379`).
   port 6379

   ## Set up password authentication (use the same password in all nodes).
   ## The password should be defined equal for both `requirepass` and `masterauth`
   ## when setting up Redis to use with Sentinel.
   requirepass redis-password-goes-here
   masterauth redis-password-goes-here
   ```

1. Restart the Redis service for the changes to take effect.

### Step 2. Configuring the replica Redis instances

Assuming that the Redis replica instance IP is `10.0.0.2`:

1. [Install Redis](../../install/installation.md#8-redis).
1. Edit `/etc/redis/redis.conf`:

   ```conf
   ## Define a `bind` address pointing to a local IP that your other machines
   ## can reach you. If you really need to bind to an external accessible IP, make
   ## sure you add extra firewall rules to prevent unauthorized access:
   bind 10.0.0.2

   ## Define a `port` to force redis to listen on TCP so other machines can
   ## connect to it (default port is `6379`).
   port 6379

   ## Set up password authentication (use the same password in all nodes).
   ## The password should be defined equal for both `requirepass` and `masterauth`
   ## when setting up Redis to use with Sentinel.
   requirepass redis-password-goes-here
   masterauth redis-password-goes-here

   ## Define `replicaof` pointing to the Redis primary instance with IP and port.
   replicaof 10.0.0.1 6379
   ```

1. Restart the Redis service for the changes to take effect.
1. Go through the steps again for all the other replica nodes.

### Step 3. Configuring the Redis Sentinel instances

Sentinel is a special type of Redis server. It inherits most of the basic
configuration options you can define in `redis.conf`, with specific ones
starting with `sentinel` prefix.

Assuming that the Redis Sentinel is installed on the same instance as Redis
primary with IP `10.0.0.1` (some settings might overlap with the primary):

1. [Install Redis Sentinel](https://redis.io/docs/latest/operate/oss_and_stack/management/sentinel/).
1. Edit `/etc/redis/sentinel.conf`:

   ```conf
   ## Define a `bind` address pointing to a local IP that your other machines
   ## can reach you. If you really need to bind to an external accessible IP, make
   ## sure you add extra firewall rules to prevent unauthorized access:
   bind 10.0.0.1

   ## Define a `port` to force Sentinel to listen on TCP so other machines can
   ## connect to it (default port is `6379`).
   port 26379

   ## Set up password authentication (use the same password in all nodes).
   ## The password should be defined equal for both `requirepass` and `masterauth`
   ## when setting up Redis to use with Sentinel.
   requirepass redis-password-goes-here
   masterauth redis-password-goes-here

   ## Define with `sentinel auth-pass` the same shared password you have
   ## defined for both Redis primary and replicas instances.
   sentinel auth-pass gitlab-redis redis-password-goes-here

   ## Define with `sentinel monitor` the IP and port of the Redis
   ## primary node, and the quorum required to start a failover.
   sentinel monitor gitlab-redis 10.0.0.1 6379 2

   ## Define with `sentinel down-after-milliseconds` the time in `ms`
   ## that an unresponsive server is considered down.
   sentinel down-after-milliseconds gitlab-redis 10000

   ## Define a value for `sentinel failover_timeout` in `ms`. This has multiple
   ## meanings:
   ##
   ## * The time needed to re-start a failover after a previous failover was
   ##   already tried against the same primary by a given Sentinel, is two
   ##   times the failover timeout.
   ##
   ## * The time needed for a replica replicating to a wrong primary according
   ##   to a Sentinel current configuration, to be forced to replicate
   ##   with the right primary, is exactly the failover timeout (counting since
   ##   the moment a Sentinel detected the misconfiguration).
   ##
   ## * The time needed to cancel a failover that is already in progress but
   ##   did not produced any configuration change (REPLICAOF NO ONE yet not
   ##   acknowledged by the promoted replica).
   ##
   ## * The maximum time a failover in progress waits for all the replicas to be
   ##   reconfigured as replicas of the new primary. However even after this time
   ##   the replicas are reconfigured by the Sentinels anyway, but not with
   ##   the exact parallel-syncs progression as specified.
   sentinel failover_timeout 30000
   ```

1. Restart the Redis service for the changes to take effect.
1. Go through the steps again for all the other Sentinel nodes.

### Step 4. Configuring the GitLab application

You can enable or disable Sentinel support at any time in new or existing
installations. From the GitLab application perspective, all it requires is
the correct credentials for the Sentinel nodes.

While it doesn't require a list of all Sentinel nodes, in case of a failure,
it needs to access at least one of listed ones.

The following steps should be performed in the GitLab application server
which ideally should not have Redis or Sentinels in the same machine:

1. Edit `/home/git/gitlab/config/resque.yml` following the example in
   [`resque.yml.example`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/config/resque.yml.example), and uncomment the Sentinel lines, pointing to
   the correct server credentials:

   ```yaml
   # resque.yaml
   production:
     url: redis://:redi-password-goes-here@gitlab-redis/
     sentinels:
       -
         host: 10.0.0.1
         port: 26379  # point to sentinel, not to redis port
       -
         host: 10.0.0.2
         port: 26379  # point to sentinel, not to redis port
       -
         host: 10.0.0.3
         port: 26379  # point to sentinel, not to redis port
   ```

1. [Restart GitLab](../restart_gitlab.md#self-compiled-installations) for the changes to take effect.

## Example of minimal configuration with 1 primary, 2 replicas and 3 sentinels

In this example we consider that all servers have an internal network
interface with IPs in the `10.0.0.x` range, and that they can connect
to each other using these IPs.

In a real world usage, you would also set up firewall rules to prevent
unauthorized access from other machines, and block traffic from the
outside ([Internet](https://gitlab.com/gitlab-org/gitlab-foss/uploads/c4cc8cd353604bd80315f9384035ff9e/The_Internet_IT_Crowd.png)).

For this example, **Sentinel 1** is configured in the same machine as the
**Redis Primary**, **Sentinel 2** in the same machine as **Replica 1**, and
**Sentinel 3** in the same machine as **Replica 2**.

Here is a list and description of each **machine** and the assigned **IP**:

- `10.0.0.1`: Redis Primary + Sentinel 1
- `10.0.0.2`: Redis Replica 1 + Sentinel 2
- `10.0.0.3`: Redis Replica 2 + Sentinel 3
- `10.0.0.4`: GitLab application

After the initial configuration, if a failover is initiated
by the Sentinel nodes, the Redis nodes are reconfigured and the **Primary**
changes permanently (including in `redis.conf`) from one node to the other,
until a new failover is initiated again.

The same thing happens with `sentinel.conf` that is overridden after the
initial execution, after any new sentinel node starts watching the **Primary**,
or a failover promotes a different **Primary** node.

### Example configuration for Redis primary and Sentinel 1

1. In `/etc/redis/redis.conf`:

   ```conf
   bind 10.0.0.1
   port 6379
   requirepass redis-password-goes-here
   masterauth redis-password-goes-here
   ```

1. In `/etc/redis/sentinel.conf`:

   ```conf
   bind 10.0.0.1
   port 26379
   sentinel auth-pass gitlab-redis redis-password-goes-here
   sentinel monitor gitlab-redis 10.0.0.1 6379 2
   sentinel down-after-milliseconds gitlab-redis 10000
   sentinel failover_timeout 30000
   ```

1. Restart the Redis service for the changes to take effect.

### Example configuration for Redis replica 1 and Sentinel 2

1. In `/etc/redis/redis.conf`:

   ```conf
   bind 10.0.0.2
   port 6379
   requirepass redis-password-goes-here
   masterauth redis-password-goes-here
   replicaof 10.0.0.1 6379
   ```

1. In `/etc/redis/sentinel.conf`:

   ```conf
   bind 10.0.0.2
   port 26379
   sentinel auth-pass gitlab-redis redis-password-goes-here
   sentinel monitor gitlab-redis 10.0.0.1 6379 2
   sentinel down-after-milliseconds gitlab-redis 10000
   sentinel failover_timeout 30000
   ```

1. Restart the Redis service for the changes to take effect.

### Example configuration for Redis replica 2 and Sentinel 3

1. In `/etc/redis/redis.conf`:

   ```conf
   bind 10.0.0.3
   port 6379
   requirepass redis-password-goes-here
   masterauth redis-password-goes-here
   replicaof 10.0.0.1 6379
   ```

1. In `/etc/redis/sentinel.conf`:

   ```conf
   bind 10.0.0.3
   port 26379
   sentinel auth-pass gitlab-redis redis-password-goes-here
   sentinel monitor gitlab-redis 10.0.0.1 6379 2
   sentinel down-after-milliseconds gitlab-redis 10000
   sentinel failover_timeout 30000
   ```

1. Restart the Redis service for the changes to take effect.

### Example configuration of the GitLab application

1. Edit `/home/git/gitlab/config/resque.yml`:

   ```yaml
   production:
     url: redis://:redis-password-goes-here@gitlab-redis/
     sentinels:
       -
         host: 10.0.0.1
         port: 26379  # point to sentinel, not to redis port
       -
         host: 10.0.0.2
         port: 26379  # point to sentinel, not to redis port
       -
         host: 10.0.0.3
         port: 26379  # point to sentinel, not to redis port
   ```

1. [Restart GitLab](../restart_gitlab.md#self-compiled-installations) for the changes to take effect.

## Troubleshooting

See the [Redis troubleshooting guide](troubleshooting.md).
