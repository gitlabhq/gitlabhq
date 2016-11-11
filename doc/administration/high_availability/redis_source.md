# Configuring Redis for GitLab HA (Source Install)

We highly recommend that you use Omnibus GitLab packages, as we can optimize
required packages specifically for GitLab, and we will take care of upgrading
to the latest supported version.

If you are building packages for a specific distro, or trying to build some
internal automation, you can check this documentation to learn about the
minimal setup, required changes, etc.

If you want to see the documentation for Omnibus GitLab Install, please
[read it here](redis.md).

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**

- [Configure your own Redis server](#configure-your-own-redis-server)
  - [Configuring Master Redis instance](#configuring-master-redis-instance)
  - [Configuring Slave Redis instances](#configuring-slave-redis-instances)
  - [Configuring Redis Sentinel instances](#configuring-redis-sentinel-instances)
- [GitLab setup](#gitlab-setup)
- [Example configurations](#example-configurations)
  - [Configuring Redis Master](#configuring-redis-master)
  - [Configuring Redis Slaves](#configuring-redis-slaves)
  - [Configuring Redis Sentinel](#configuring-redis-sentinel)
- [Troubleshooting](#troubleshooting)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Configure your own Redis server

Redis server must be configured to use TCP connection instead of socket,
and since Redis `3.2`, you must define a password to receive external
connections (`requirepass`).

You will also need to define equal password for slave password definition
(`masterauth`), in the same instance, if you are using Redis with Sentinel.

To configure Redis to use TCP connection you need to define both
`bind` and `port`. You can bind to all interfaces (`0.0.0.0`) or specify the
IP of the desired interface (for ex. one from an internal network).


### Configuring Master Redis instance

You need to make the following changes in `redis.conf`:

1. Define a `bind` address pointing to a local IP that your other machines
   can reach you. If you really need to bind to an external accessible IP, make
   sure you add extra firewall rules to prevent unauthorized access:

1. Define a `port` to force redis to listen on TCP so other machines can
   connect to it (default port is `6379`).

1. Set up password authentication (use the same password in all nodes).
   The password should be defined equal for both `requirepass` and `masterauth`
   when setting up Redis to use with Sentinel.

1. Restart the Redis services for the changes to take effect.

See [example configuration](#configuring-redis-master) below.

### Configuring Slave Redis instances

1. Follow same instructions for Redis Master

1. Define `slaveof` pointing to the Redis master instance with **IP** and **port**.

1. Restart the Redis services for the changes to take effect.

See [example configuration](#configuring-redis-slaves) below.

### Configuring Redis Sentinel instances

Sentinel is a special type of Redis server. It inherits most of the basic
configuration options you can define in `redis.conf`, with specific ones
starting with `sentinel` prefix.

You will need to define the initial configs to enable connectivity:

1. Define a `bind` address pointing to a local IP that your other machines
   can reach you. If you really need to bind to an external accessible IP, make
   sure you add extra firewall rules to prevent unauthorized access:

1. Define a `port` to force sentinel to listen on TCP so other machines can
   connect to it (default port is `26379`).

And the sentinel specific ones:

1. Define with `sentinel auth-pass` the same shared password you have
   defined for both Redis **Master** and **Slaves** instances.

1. Define with `sentinel monitor` the **IP** and **port** of the Redis
   **Master** node, and the **quorum** required to start a failover.
   If you need more information to understand about quorum, please
   read the detailed explanation in the [HA documentation for Omnibus Installs](redis.md).

1. Define with `sentinel down-after-milliseconds` the amount in `ms` of time
   that an unresponsive server will be considered down.

1. Define a value for `sentinel failover_timeout` in `ms`. This has multiple
   meanings:

   * The time needed to re-start a failover after a previous failover was
     already tried against the same master by a given Sentinel, is two
     times the failover timeout.

   * The time needed for a slave replicating to a wrong master according
     to a Sentinel current configuration, to be forced to replicate
     with the right master, is exactly the failover timeout (counting since
     the moment a Sentinel detected the misconfiguration).

   * The time needed to cancel a failover that is already in progress but
     did not produced any configuration change (SLAVEOF NO ONE yet not
     acknowledged by the promoted slave).

   * The maximum time a failover in progress waits for all the slaves to be
     reconfigured as slaves of the new master. However even after this time
     the slaves will be reconfigured by the Sentinels anyway, but not with
     the exact parallel-syncs progression as specified.

See [example configuration](#configuring-redis-sentinel) below.

## GitLab setup

You can enable or disable Sentinel support at any time in new or existing
installations. From the GitLab application perspective, all it requires is
the correct credentials for the Sentinel nodes.

While it doesn't require a list of all Sentinel nodes, in case of a failure,
it needs to access at one of listed ones.

>**Note:**
The following steps should be performed in the [GitLab application server](gitlab.md)
which ideally should not have Redis or Sentinels in the same machine for a HA setup.

1. Edit `/home/git/gitlab/config/resque.yml` following the example in
   `/home/git/gitlab/config/resque.yml.example`, and uncomment the sentinels
   lines, pointing to the correct server credentials.

1. Restart GitLab for the changes to take effect.

## Example configurations

In this example we consider that all servers have an internal network
interface with IPs in the `10.0.0.x` range, and that they can connect
to each other using these IPs.

In a real world usage, you would also setup firewall rules to prevent
unauthorized access from other machines, and block traffic from the
outside (Internet).

We will use the same `3` nodes with **Redis** + **Sentinel** topology
discussed in the [Configuring Redis for GitLab HA](redis.md) documentation.

Here is a list and description of each **machine** and the assigned **IP**:

* `10.0.0.1`: Redis Master + Sentinel 1
* `10.0.0.2`: Redis Slave 1 + Sentinel 2
* `10.0.0.2`: Redis Slave 2 + Sentinel 3

Please note that after the initial configuration, if a failover is initiated
by the Sentinel nodes, the Redis nodes will be reconfigured and the **Master**
will change permanently (including in `redis.conf`) from one node to the other,
until a new failover is initiated again.

The same thing will happen with `sentinel.conf` that will be overridden after the
initial execution, after any new sentinel node starts watching the **Master**,
or a failover promotes a different **Master** node.

### Configuring Redis Master

**Example configation for Redis Master - `redis.conf`:**

```conf
bind 10.0.0.1
port 6379
requirepass redis-password-goes-here
masterauth redis-password-goes-here
```

### Configuring Redis Slaves

**Example configation for Slave 1 - `redis.conf`:**

```conf
bind 10.0.0.2
port 6379
requirepass redis-password-goes-here
masterauth redis-password-goes-here

# IP and port of the master Redis server
slaveof 10.0.0.1 6379
```

**Example configation for Slave 2 - `redis.conf`:**

```conf
bind 10.0.0.3
port 6379
requirepass redis-password-goes-here
masterauth redis-password-goes-here

# IP and port of the master Redis server
slaveof 10.0.0.1 6379
```

### Configuring Redis Sentinel

For this example, **Sentinel 1** will be configured in the same machine as the
**Redis Master**, **Sentinel 2** and **Sentinel 3** in the same machines as the
**Slave 1** and **Slave 2** respectively.

**Example configation for Sentinel 1 - `sentinel.conf`:**

```conf
bind 10.0.0.1
port 26379
sentinel auth-pass gitlab-redis redis-password-goes-here
sentinel monitor gitlab-redis 10.0.0.1 6379 2
sentinel down-after-milliseconds gitlab-redis 10000
sentinel failover_timeout 30000
```

**Example configation for Sentinel 2 - `sentinel.conf`:**

```conf
bind 10.0.0.2
port 26379
sentinel auth-pass gitlab-redis redis-password-goes-here
sentinel monitor gitlab-redis 10.0.0.1 6379 2
sentinel down-after-milliseconds gitlab-redis 10000
sentinel failover_timeout 30000
```

**Example configation for Sentinel 3 - `sentinel.conf`:**

```conf
bind 10.0.0.3
port 26379
sentinel auth-pass gitlab-redis redis-password-goes-here
sentinel monitor gitlab-redis 10.0.0.1 6379 2
sentinel down-after-milliseconds gitlab-redis 10000
sentinel failover_timeout 30000
```

## Troubleshooting

We have a more detailed [Troubleshooting](redis.md#troubleshooting) explained in the documentation for Omnibus
Install. Here we will list only the things that are specific to a **Source** install.

If you get an error in GitLab like: `Redis::CannotConnectError: No sentinels available.`,
there may be something wrong with your configuration files or it can be related
to [this issue][gh-531].

It's a bit non-intuitive the way you have to config `resque.yml` and
`sentinel.conf`, otherwise `redis-rb` will not work properly.

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

When in doubt, please read [Redis Sentinel documentation](http://redis.io/topics/sentinel)

[gh-531]: https://github.com/redis/redis-rb/issues/531
