# Configuring Redis for GitLab HA

You can choose to install and manage Redis yourself, or you can use the one
that comes bundled with Omnibus GitLab packages.

> **Note:** Redis does not require authentication by default. See
  [Redis Security](http://redis.io/topics/security) documentation for more
  information. We recommend using a combination of a Redis password and tight
  firewall rules to secure your Redis service.

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**

- [Configure your own Redis server](#configure-your-own-redis-server)
- [Configure Redis using Omnibus](#configure-redis-using-omnibus)
- [Experimental Redis Sentinel support](#experimental-redis-sentinel-support)
- [Redis Sentinel support](#redis-sentinel-support)
  - [Prerequisites](#prerequisites)
  - [Redis setup](#redis-setup)
    - [Existing single-machine installation](#existing-single-machine-installation)
    - [Installation from source](#installation-from-source)
    - [Omnibus packages](#omnibus-packages)
  - [Configuring Sentinel](#configuring-sentinel)
    - [How sentinel handles a failover](#how-sentinel-handles-a-failover)
    - [Sentinel setup](#sentinel-setup)
      - [Community Edition](#community-edition)
      - [Enterprise Edition](#enterprise-edition)
  - [GitLab setup](#gitlab-setup)
- [Troubleshooting](#troubleshooting)
  - [Redis replication](#redis-replication)
  - [Sentinel](#sentinel)
    - [Omnibus GitLab](#omnibus-gitlab)
    - [Install from Source](#install-from-source)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Configure your own Redis server

If you're hosting GitLab on a cloud provider, you can optionally use a
managed service for Redis. For example, AWS offers a managed ElastiCache service
that runs Redis.

## Configure Redis using Omnibus

If you don't want to bother setting up your own Redis server, you can use the
one bundled with Omnibus. In this case, you should disable all services except
Redis.

1. Download/install Omnibus GitLab using **steps 1 and 2** from
   [GitLab downloads](https://about.gitlab.com/downloads). Do not complete other
   steps on the download page.
1. Create/edit `/etc/gitlab/gitlab.rb` and use the following configuration.
   Be sure to change the `external_url` to match your eventual GitLab front-end
   URL:

    ```ruby
    external_url 'https://gitlab.example.com'

    # Disable all services except Redis
    redis['enable'] = true
    bootstrap['enable'] = false
    nginx['enable'] = false
    postgresql['enable'] = false
    gitlab_rails['enable'] = false
    mailroom['enable'] = false

    # Redis configuration
    redis['port'] = 6379
    redis['bind'] = '0.0.0.0'

    # If you wish to use Redis authentication (recommended)
    redis['password'] = 'redis-password-goes-here'
    ```

1. Run `sudo gitlab-ctl reconfigure` to install and configure Redis.

    > **Note**: This `reconfigure` step will result in some errors.
      That's OK - don't be alarmed.

1. Run `touch /etc/gitlab/skip-auto-migrations` to prevent database migrations
   from running on upgrade. Only the primary GitLab application server should
   handle migrations.

## Experimental Redis Sentinel support

   > Experimental Redis Sentinel support was [Introduced][ce-1877] in GitLab 8.11.
     Starting with 8.13, Redis Sentinel is no longer experimental.
     If you used with versions `< 8.13` before, please check the updated
     documentation below.

## Redis Sentinel support

Since GitLab 8.11, you can configure a list of Redis Sentinel servers that
will monitor a group of Redis servers to provide you with a standard failover
support.

To get a better understanding on how to correctly setup Sentinel, please read
the [Redis Sentinel documentation](http://redis.io/topics/sentinel) first, as
failing to configure it correctly can lead to data loss.

Redis Sentinel can handle the most important tasks in a HA environment to help
keep servers online with minimal to no downtime:

- Monitors master and slave instances to see if they are available
- Promote a slave to master when the master fails.
- Demote a master to slave when failed master comes back online (to prevent
  data-partitioning).
- Can be queried by clients to always connect to the correct master server.

The configuration consists of three parts:

- Setup Redis Master and Slave nodes
- Setup Sentinel nodes
- Setup GitLab

### Prerequisites

You need at least `3` independent machines: physical, or VMs running into
distinct physical machines.

If you fail to provision the machines in that specific way, any issue with
the shared environment can bring your entire setup down.

Read carefully how to configure those components below.

### Redis setup

You must have at least `3` Redis servers: `1` Master, `2` Slaves, and they need to
be each in a independent machine (see explanation above).

They should be configured the same way and with similar server specs, as
in a failover situation, any `Slave` can be elected as the new `Master` by
the Sentinel servers.

With Sentinel, you must define a password to protect the access as both
Sentinel instances and other redis instances should be able to talk to
each other over the network.

You'll need to define both `requirepass` and `masterauth` in all
nodes. At any time during a failover the Sentinels can reconfigure a node
and change it's status from `Master` to `Slave` and vice versa.

Initial `Slave` nodes require an additional `slaveof` setting in `redis.conf`
pointing to the initial `Master`.

#### Existing single-machine installation

If you already have a single-machine GitLab install running, you will need to
replicate from this machine first, before de-activating the Redis instance
inside it.

Your single-machine install will be the initial `Master`, and the `3` others
should be configured as `Slave` pointing to this machine.

After replication catchs-up, you will need to stop services in the
single-machine install, to rotate the `Master` to one of the new nodes.

Make the required changes in configuration and restart the new nodes again.

To disable redis in the single install, edit `/etc/gitlab/gitlab.rb`:

```ruby
redis['enable'] = false
```

#### Installation from source

**Configuring Master Redis instance**

You need to make the following changes in `redis.conf`:

1. Define a `bind` address pointing to a local IP that your other machines
   can reach you. If you really need to bind to an external acessible IP, make
   sure you add extra firewall rules to prevent unauthorized access:

   ```conf
   # By default, if no "bind" configuration directive is specified, Redis listens
   # for connections from all the network interfaces available on the server.
   # It is possible to listen to just one or multiple selected interfaces using
   # the "bind" configuration directive, followed by one or more IP addresses.
   #
   # Examples:
   #
   # bind 192.168.1.100 10.0.0.1
   # bind 127.0.0.1 ::1
   bind 0.0.0.0 # This will bind to all interfaces
   ```

1. Define a `port` to force redis to listin on TCP so other machines can
   connect to it:

   ```conf
   # Accept connections on the specified port, default is 6379 (IANA #815344).
   # If port 0 is specified Redis will not listen on a TCP socket.
   port 6379
   ```

1. Set up password authentication (use the same password in all nodes)

    ```conf
    requirepass "redis-password-goes-here"
    masterauth "redis-password-goes-here"
    ```

1. Restart the Redis services for the changes to take effect.

**Configuring Slave Redis instance**

1. Follow same instructions from master, with the extra change in `redis.conf`:

   ```conf
   # IP and port of the master Redis server
   slaveof 10.10.10.10 6379
   ```

1. Restart the Redis services for the changes to take effect.

#### Omnibus packages

You need to install the Omnibus GitLab package in `3` independent machines.

**Configuring Master Redis instance**

You will need to configure the following:

1. Define a `redis['bind']` address pointing to a local IP that your other machines
   can reach you. If you really need to bind to an external acessible IP, make
   sure you add extra firewall rules to prevent unauthorized access.
1. Define a `redis['port']` so redis can listen for TCP requests which will
   allow other machines to connect to it.
1. Set up a password authentication with `redis['master_password']` (use the same
   password in all nodes).

In `/etc/gitlab/gitlab.rb`:

```ruby
## Redis TCP support (will disable UNIX socket transport)
redis['bind'] = '0.0.0.0' # or specify an IP to bind to a single one
redis['port'] = 6379
redis['requirepass'] = 'redis-password-goes-here'
redis['master_password'] = 'redis-password-goes-here'
```

Reconfigure Omnibus GitLab for the changes to take effect: `sudo gitlab-ctl reconfigure`

**Configuring Slave Redis instances**

You need to make the same changes listed for the `Master` instance,
with an additional `Slave` section as in the example below:

```ruby
redis['bind'] = '0.0.0.0' # or specify an IP to bind to a single one
redis['port'] = 6379
redis['requirepass'] = 'redis-password-goes-here'
redis['master_password'] = 'redis-password-goes-here'

## Slave redis instance
redis['master'] = false
redis['master_ip'] = '10.10.10.10' # IP of master Redis server
redis['master_port'] = 6379 # Port of master Redis server
```

Reconfigure Omnibus GitLab for the changes to take effect: `sudo gitlab-ctl reconfigure`

---

Now that the Redis servers are all set up, let's configure the Sentinel
servers.

If you are not sure if your Redis servers are working and replicating
correctly, please read the [Troubleshooting  Replication](#troubleshooting-replication)
and fix it before proceeding with Sentinel setup.

### Configuring Sentinel

You must have at least `3` Redis Sentinel servers, and they need to
be each in a independent machine. You can configure them in the same
machines where you've configured the other Redis servers.

This number is required for the consensus algorithm to be effective
in the case of a failure. **You should always have and `odd` number
of Sentinel nodes provisioned**.

#### How sentinel handles a failover

If (`quorum` value of) Sentinels  agree the fact the `master` is not reachable,
Sentinels will try to elect a temporary `Leader`. The **Majority** of the
Sentinels must agree to start a failover.

If you don't have the **Majority** of the Sentinels online (for example if you
are under a network partitioning), a failover **will not be started**.

For example, for a cluster of `3` Sentinels, at least `2` must agree on a
`Leader`. If you have total of `5` at least `3` must agree on a `Leader`.

The `quorum` is only used to detect failure, not to elect the `Leader`.

Official [Sentinel documentation](http://redis.io/topics/sentinel#example-sentinel-deployments)
also lists different network topologies and warns againts situations like
network partition and how it can affect the state of the HA solution. Make
sure you read it carefully and understand the implications in your current
setup.

GitLab Enterprise Edition provides [automated way to setup and run](#sentinel-setup-ee-only) the Sentinel daemon.

#### Sentinel setup

##### Community Edition
With GitLab Community Edition, you need to install, configure, execute and
monitor Sentinel from source. Omnibus GitLab Community Edition package does
not support Sentinel configuration.

A minimal configuration file (`sentinel.conf`) should contain the following:

```conf
bind 0.0.0.0 # bind to all interfaces or change to a specific IP
port 26379 # default sentinel port
sentinel auth-pass gitlab-redis redis-password-goes-here
sentinel monitor gitlab-redis 10.0.0.1 6379 2
sentinel down-after-milliseconds gitlab-redis 10000
sentinel config-epoch gitlab-redis 0
sentinel leader-epoch gitlab-redis 0
```

##### Enterprise Edition

To setup sentinel, you edit `/etc/gitlab/gitlab.rb` file:

```ruby

## When you install Sentinel in a separate machine, you need to control which
## other services will be running in it. Take a look at the following variables
## and enable or disable whenever it fits your strategy:

## Enabled Redis and Sentinel services
redis['enable'] = true
sentinel['enable'] = true

# Disabled all other services
bootstrap['enable'] = false
nginx['enable'] = false
postgresql['enable'] = false
gitlab_rails['enable'] = false
mailroom['enable'] = false

## Configure Redis
redis['master_name'] = 'gitlab-redis' # must be the same in every sentinel node
redis['master_ip'] = '10.0.0.1' # ip of the initial master redis instance
redis['master_port'] = 6379 # port of the initial master redis instance
redis['master_password'] = 'your-secure-password-here' # the same value defined in redis['password'] in the master instance

## Configure Sentinel
# sentinel['port'] = 26379 # uncomment to change default port

## Quorum must reflect the amount of voting sentinels it take to start a failover.
## Value must NOT be greater then the ammount of sentinels.
##
## The quorum can be used to tune Sentinel in two ways:
## 1. If a the quorum is set to a value smaller than the majority of Sentinels
##    we deploy, we are basically making Sentinel more sensible to master failures,
##    triggering a failover as soon as even just a minority of Sentinels is no longer
##    able to talk with the master.
## 1. If a quorum is set to a value greater than the majority of Sentinels, we are
##    making Sentinel able to failover only when there are a very large number (larger
##    than majority) of well connected Sentinels which agree about the master being down.s
sentinel['quorum'] = 2

## Consider unresponsive server down after x amount of ms.
# sentinel['down_after_milliseconds'] = 10000

## Specifies the failover timeout in milliseconds. It is used in many ways:
##
## - The time needed to re-start a failover after a previous failover was
##   already tried against the same master by a given Sentinel, is two
##   times the failover timeout.
##
## - The time needed for a slave replicating to a wrong master according
##   to a Sentinel current configuration, to be forced to replicate
##   with the right master, is exactly the failover timeout (counting since
##   the moment a Sentinel detected the misconfiguration).
##
## - The time needed to cancel a failover that is already in progress but
##   did not produced any configuration change (SLAVEOF NO ONE yet not
##   acknowledged by the promoted slave).
##
## - The maximum time a failover in progress waits for all the slaves to be
##   reconfigured as slaves of the new master. However even after this time
##   the slaves will be reconfigured by the Sentinels anyway, but not with
##   the exact parallel-syncs progression as specified.
# sentinel['failover_timeout'] = 60000
```

---

The final part is to inform the main GitLab application server of the Redis
master and the new sentinels servers.

### GitLab setup

You can enable or disable sentinel support at any time in new or existing
installations. From the GitLab application perspective, all it requires is
the correct credentials for the master Redis and for a few Sentinel nodes.

It doesn't require a list of all Sentinel nodes, as in case of a failure,
the application will need to query only one of them.

>**Note:**
The following steps should be performed in the [GitLab application server](gitlab.md).

**For source based installations**

1. Edit `/home/git/gitlab/config/resque.yml` following the example in
   `/home/git/gitlab/config/resque.yml.example`, and uncomment the sentinels
   line, changing to the correct server credentials.
1. Restart GitLab for the changes to take effect.

**For Omnibus installations**

1. Edit `/etc/gitlab/gitlab.rb` and add/change the following lines:

    ```ruby
    redis['master_name'] = "gitlab-redis"
    redis['master_password'] = 'redis-password-goes-here'
    gitlab_rails['redis_sentinels'] = [
      {'host' => '10.10.10.1', 'port' => 26379},
      {'host' => '10.10.10.2', 'port' => 26379},
      {'host' => '10.10.10.3', 'port' => 26379}
    ]
    ```

1. [Reconfigure] the GitLab for the changes to take effect.

## Troubleshooting

There are a lot of moving parts that needs to be taken care carefully
in order for the HA setup to work as expected.

Before proceeding with the troubleshooting below, check your firewall
rules:
- Redis machines
   - Accept TCP connection in `6379`
   - Connect to the other Redis machines via TCP in `6379`
- Sentinel machines
   - Accept TCP connection in `26379`
   - Connect to other Sentinel machines via TCP in `26379`
   - Connect to the Redis machines via TCP in `6379`

### Redis replication

You can check if everything is correct by connecting to each server using
`redis-cli` application, and sending the `INFO` command.

If authentication was correctly defined, it should fail with:
`NOAUTH Authentication required` error. Try to authenticate with the
previous defined password with `AUTH redis-password-goes-here` and
try the `INFO` command again.

Look for the `# Replication` section where you should see some important
information like the `role` of the server.

When connected to a `master` redis, you will see the number of connected
`slaves`, and a list of each with connection details:

```
# Replication
role:master
connected_slaves:1
slave0:ip=10.133.5.21,port=6379,state=online,offset=208037514,lag=1
master_repl_offset:208037658
repl_backlog_active:1
repl_backlog_size:1048576
repl_backlog_first_byte_offset:206989083
repl_backlog_histlen:1048576
```

When it's a `slave`, you will see details of the master connection and if
its `up` or `down`:

```
# Replication
role:slave
master_host:10.133.1.58
master_port:6379
master_link_status:up
master_last_io_seconds_ago:1
master_sync_in_progress:0
slave_repl_offset:208096498
slave_priority:100
slave_read_only:1
connected_slaves:0
master_repl_offset:0
repl_backlog_active:0
repl_backlog_size:1048576
repl_backlog_first_byte_offset:0
repl_backlog_histlen:0
```

### Sentinel

#### Omnibus GitLab

If you get an error like: `Redis::CannotConnectError: No sentinels available.`,
there may be something wrong with your configuration files or it can be related
to [this issue][gh-531].

You must make sure you are defining the same value in `redis['master_name']`
and `redis['master_pasword']` as you defined for your sentinel node.

The way the redis connector `redis-rb` works with sentinel is a bit
non-intuitive. We try to hide the complexity in omnibus, but it still requires
a few extra configs.

#### Install from Source

If you get an error like: `Redis::CannotConnectError: No sentinels available.`,
there may be something wrong with your configuration files or it can be related
to [this issue][gh-531].

It's a bit non-intuitive the way you have to config `resque.yml` and
`sentinel.conf`, otherwise `redis-rb` will not work properly.

The `master-group-name` ('gitlab-redis') defined in (`sentinel.conf`)
**must** be used as the hostname in GitLab (`resque.yml` for source installations
or `gitlab-rails['redis_*']` in Omnibus):

```conf
# sentinel.conf:
sentinel monitor gitlab-redis 10.10.10.10 6379 2
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
      host: slave1.example.com # or use ip
      port: 26380 # point to sentinel, not to redis port
    -
      host: slave2.exampl.com # or use ip
      port: 26381 # point to sentinel, not to redis port
```

When in doubt, please read [Redis Sentinel documentation](http://redis.io/topics/sentinel)

---

To make sure your configuration is correct:

1. SSH into your GitLab application server
1. Enter the Rails console:

    ```
    # For Omnibus installations
    sudo gitlab-rails console

    # For source installations
    sudo -u git rails console production
    ```

1. Run in the console:

    ```ruby
    redis = Redis.new(Gitlab::Redis.params)
    redis.info
    ```

    Keep this screen open and try to simulate a failover below.

1. To simulate a failover on master Redis, SSH into the Redis server and run:

    ```bash
    # port must match your master redis port
     redis-cli -h localhost -p 6379 DEBUG sleep 60
    ```

1. Then back in the Rails console from the first step, run:

    ```
    redis.info
    ```

    You should see a different port after a few seconds delay
    (the failover/reconnect time).

---

Read more on high-availability configuration:

1. [Configure the database](database.md)
1. [Configure NFS](nfs.md)
1. [Configure the GitLab application servers](gitlab.md)
1. [Configure the load balancers](load_balancer.md)

[ce-1877]: https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/1877
[restart]: ../restart_gitlab.md#installations-from-source
[reconfigure]: ../restart_gitlab.md#omnibus-gitlab-reconfigure
[gh-531]: https://github.com/redis/redis-rb/issues/531
[gh-534]: https://github.com/redis/redis-rb/issues/534
