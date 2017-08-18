# Configuring non-Omnibus Redis for GitLab HA

This is the documentation for configuring a Highly Available Redis setup when
you have installed Redis all by yourself and not using the bundled one that
comes with the Omnibus packages.

Note also that you may elect to override all references to
`/home/git/gitlab/config/resque.yml` in accordance with the advanced Redis
settings outlined in
[Configuration Files Documentation](https://gitlab.com/gitlab-org/gitlab-ce/blob/master/config/README.md).

We cannot stress enough the importance of reading the
[Overview section](redis.md#overview) of the Omnibus Redis HA as it provides
some invaluable information to the configuration of Redis. Please proceed to
read it before going forward with this guide.

We also highly recommend that you use the Omnibus GitLab packages, as we
optimize them specifically for GitLab, and we will take care of upgrading Redis
to the latest supported version.

If you're not sure whether this guide is for you, please refer to
[Available configuration setups](redis.md#available-configuration-setups) in
the Omnibus Redis HA documentation.

## Configuring your own Redis server

This is the section where we install and setup the new Redis instances.

### Prerequisites

- All Redis servers in this guide must be configured to use a TCP connection
  instead of a socket. To configure Redis to use TCP connections you need to
  define both `bind` and `port` in the Redis config file. You can bind to all
  interfaces (`0.0.0.0`) or specify the IP of the desired interface
  (e.g., one from an internal network).
- Since Redis 3.2, you must define a password to receive external connections
  (`requirepass`).
- If you are using Redis with Sentinel, you will also need to define the same
  password for the slave password definition (`masterauth`) in the same instance.

In addition, read the prerequisites as described in the
[Omnibus Redis HA document](redis.md#prerequisites) since they provide some
valuable information for the general setup.

### Step 1. Configuring the master Redis instance

Assuming that the Redis master instance IP is `10.0.0.1`:

1. [Install Redis](../../install/installation.md#6-redis)
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

### Step 2. Configuring the slave Redis instances

Assuming that the Redis slave instance IP is `10.0.0.2`:

1. [Install Redis](../../install/installation.md#6-redis)
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

    ## Define `slaveof` pointing to the Redis master instance with IP and port.
    slaveof 10.0.0.1 6379
    ```

1. Restart the Redis service for the changes to take effect.
1. Go through the steps again for all the other slave nodes.

### Step 3. Configuring the Redis Sentinel instances

Sentinel is a special type of Redis server. It inherits most of the basic
configuration options you can define in `redis.conf`, with specific ones
starting with `sentinel` prefix.

Assuming that the Redis Sentinel is installed on the same instance as Redis
master with IP `10.0.0.1` (some settings might overlap with the master):

1. [Install Redis Sentinel](http://redis.io/topics/sentinel)
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
    ## defined for both Redis master and slaves instances.
    sentinel auth-pass gitlab-redis redis-password-goes-here

    ## Define with `sentinel monitor` the IP and port of the Redis
    ## master node, and the quorum required to start a failover.
    sentinel monitor gitlab-redis 10.0.0.1 6379 2

    ## Define with `sentinel down-after-milliseconds` the time in `ms`
    ## that an unresponsive server will be considered down.
    sentinel down-after-milliseconds gitlab-redis 10000

    ## Define a value for `sentinel failover_timeout` in `ms`. This has multiple
    ## meanings:
    ##
    ## * The time needed to re-start a failover after a previous failover was
    ##   already tried against the same master by a given Sentinel, is two
    ##   times the failover timeout.
    ##
    ## * The time needed for a slave replicating to a wrong master according
    ##   to a Sentinel current configuration, to be forced to replicate
    ##   with the right master, is exactly the failover timeout (counting since
    ##   the moment a Sentinel detected the misconfiguration).
    ##
    ## * The time needed to cancel a failover that is already in progress but
    ##   did not produced any configuration change (SLAVEOF NO ONE yet not
    ##   acknowledged by the promoted slave).
    ##
    ## * The maximum time a failover in progress waits for all the slaves to be
    ##   reconfigured as slaves of the new master. However even after this time
    ##   the slaves will be reconfigured by the Sentinels anyway, but not with
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

The following steps should be performed in the [GitLab application server](gitlab.md)
which ideally should not have Redis or Sentinels in the same machine for a HA
setup:

1. Edit `/home/git/gitlab/config/resque.yml` following the example in
   [resque.yml.example][resque], and uncomment the Sentinel lines, pointing to
   the correct server credentials:

    ```yaml
    # resque.yaml
    production:
      url: redis://:redi-password-goes-here@gitlab-redis/
      sentinels:
        -
          host: 10.0.0.1
          port: 26379 # point to sentinel, not to redis port
        -
          host: 10.0.0.2
          port: 26379 # point to sentinel, not to redis port
        -
          host: 10.0.0.3
          port: 26379 # point to sentinel, not to redis port
    ```

1. [Restart GitLab][restart] for the changes to take effect.

## Example of minimal configuration with 1 master, 2 slaves and 3 Sentinels

In this example we consider that all servers have an internal network
interface with IPs in the `10.0.0.x` range, and that they can connect
to each other using these IPs.

In a real world usage, you would also setup firewall rules to prevent
unauthorized access from other machines, and block traffic from the
outside ([Internet][it]).

For this example, **Sentinel 1** will be configured in the same machine as the
**Redis Master**, **Sentinel 2** and **Sentinel 3** in the same machines as the
**Slave 1** and **Slave 2** respectively.

Here is a list and description of each **machine** and the assigned **IP**:

* `10.0.0.1`: Redis Master + Sentinel 1
* `10.0.0.2`: Redis Slave 1 + Sentinel 2
* `10.0.0.3`: Redis Slave 2 + Sentinel 3
* `10.0.0.4`: GitLab application

Please note that after the initial configuration, if a failover is initiated
by the Sentinel nodes, the Redis nodes will be reconfigured and the **Master**
will change permanently (including in `redis.conf`) from one node to the other,
until a new failover is initiated again.

The same thing will happen with `sentinel.conf` that will be overridden after the
initial execution, after any new sentinel node starts watching the **Master**,
or a failover promotes a different **Master** node.

### Example configuration for Redis master and Sentinel 1

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

### Example configuration for Redis slave 1 and Sentinel 2

1. In `/etc/redis/redis.conf`:

    ```conf
    bind 10.0.0.2
    port 6379
    requirepass redis-password-goes-here
    masterauth redis-password-goes-here
    slaveof 10.0.0.1 6379
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

### Example configuration for Redis slave 2 and Sentinel 3

1. In `/etc/redis/redis.conf`:

    ```conf
    bind 10.0.0.3
    port 6379
    requirepass redis-password-goes-here
    masterauth redis-password-goes-here
    slaveof 10.0.0.1 6379
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
      url: redis://:redi-password-goes-here@gitlab-redis/
      sentinels:
        -
          host: 10.0.0.1
          port: 26379 # point to sentinel, not to redis port
        -
          host: 10.0.0.2
          port: 26379 # point to sentinel, not to redis port
        -
          host: 10.0.0.3
          port: 26379 # point to sentinel, not to redis port
    ```

1. [Restart GitLab][restart] for the changes to take effect.

## Troubleshooting

We have a more detailed [Troubleshooting](redis.md#troubleshooting) explained
in the documentation for Omnibus GitLab installations. Here we will list only
the things that are specific to a source installation.

If you get an error in GitLab like `Redis::CannotConnectError: No sentinels available.`,
there may be something wrong with your configuration files or it can be related
to [this upstream issue][gh-531].

You must make sure that `resque.yml` and `sentinel.conf` are configured correctly,
otherwise `redis-rb` will not work properly.

The `master-group-name` ('gitlab-redis') defined in (`sentinel.conf`)
**must** be used as the hostname in GitLab (`resque.yml`):

```conf
# sentinel.conf:
sentinel monitor gitlab-redis 10.0.0.1 6379 2
sentinel down-after-milliseconds gitlab-redis 10000
sentinel config-epoch gitlab-redis 0
sentinel leader-epoch gitlab-redis 0
```

```yaml
# resque.yaml
production:
  url: redis://:myredispassword@gitlab-redis/
  sentinels:
    -
      host: 10.0.0.1
      port: 26379 # point to sentinel, not to redis port
    -
      host: 10.0.0.2
      port: 26379 # point to sentinel, not to redis port
    -
      host: 10.0.0.3
      port: 26379 # point to sentinel, not to redis port
```

When in doubt, please read [Redis Sentinel documentation](http://redis.io/topics/sentinel).

[gh-531]: https://github.com/redis/redis-rb/issues/531
[downloads]: https://about.gitlab.com/downloads
[restart]: ../restart_gitlab.md#installations-from-source
[it]: https://gitlab.com/gitlab-org/gitlab-ce/uploads/c4cc8cd353604bd80315f9384035ff9e/The_Internet_IT_Crowd.png
[resque]: https://gitlab.com/gitlab-org/gitlab-ce/blob/master/config/resque.yml.example
