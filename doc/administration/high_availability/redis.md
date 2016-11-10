# Configuring Redis for GitLab HA

High Availability with Redis is possible using a **Master** x **Slave**
topology with **Sentinel** service to watch and automatically start
failover proceedings.

You can choose to install and manage Redis and Sentinel yourself, use
a hosted, managed cloud solution or you can use or you can use the one
that comes bundled with Omnibus GitLab packages.

> **Note:** Redis requires authentication for High Availability. See
  [Redis Security](http://redis.io/topics/security) documentation for more
  information. We recommend using a combination of a Redis password and tight
  firewall rules to secure your Redis service.

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**

- [Using an external Redis server](#using-an-external-redis-server)
- [High Availability with Sentinel](#high-availability-with-sentinel)
    - [Prerequisites](#prerequisites)
    - [Redis setup](#redis-setup)
    - [Sentinel setup](#sentinel-setup)
    - [Recommended setup](#recommended-setup)
- [Configuring instances using Omnibus](#configuring-instances-using-omnibus)
    - [Existing single-machine installation](#existing-single-machine-installation)
    - [Configuring Master Redis instance](#configuring-master-redis-instance)
    - [Configuring Slave Redis instances](#configuring-slave-redis-instances)
    - [Configuring Sentinel instances](#configuring-sentinel-instances)
            - [Community Edition](#community-edition)
            - [Enterprise Edition](#enterprise-edition)
    - [GitLab setup](#gitlab-setup)
- [Example Configurations](#example-configurations)
    - [Configuration for Redis Master](#configuration-for-redis-master)
    - [Configuration for Redis Slave](#configuration-for-redis-slave)
    - [Configuration for Sentinel (EE only)](#configuration-for-sentinel-ee-only)
    - [Control running services](#control-running-services)
- [Troubleshooting](#troubleshooting)
    - [Redis replication](#redis-replication)
    - [Sentinel](#sentinel)
        - [Omnibus GitLab](#omnibus-gitlab)
- [Changelog](#changelog)
    - [Experimental Redis Sentinel support](#experimental-redis-sentinel-support)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Using an external Redis server

If you're hosting GitLab on a cloud provider, you can optionally use a
managed service for Redis. For example, AWS offers a managed ElastiCache service
that runs Redis.

Managed services can provide High Availability using their own proprietary
technology and provide a transparent proxy, which means that GitLab doesn't
need any additional change, or will use Sentinel and manage it for you.

If your provider, uses Sentinel method, see [GitLab Setup](#gitlab-setup)
to understand where you need to provide the list of servers and credentials.

If you want to setup Redis by yourself, without using Omnibus, you can
read our documentation: [Configuring Redis for GitLab HA (source install)](redis_source.md).

## High Availability with Sentinel

> Since GitLab `8.11`, you can configure a list of Redis Sentinel servers that
will monitor a group of Redis servers to provide failover support.

> With GitLab `8.14`, we bundled Redis Sentinel as part of Omnibus package and
improved the way you use and configure it.

High Availability with Redis requires a few things:

- Multiple Redis instances
- Run Redis in a **Master** x **Slave** topology
- Multiple Sentinel instances
- Application support and visibility to all Sentinel and Redis instances

Redis Sentinel can handle the most important tasks in a HA environment to help
keep servers online with minimal to no downtime:

- Monitors **Master** and **Slaves** instances to see if they are available
- Promote a **Slave** to **Master** when the **Master** fails
- Demote a **Master** to **Slave** when failed **Master** comes back online (to prevent
  data-partitioning)
- Can be queried by clients to always connect to the current **Master** server

When a **Master** fails to respond, it's the client's responsibility to handle
timeout and reconnect (querying a **Sentinel** for a new **Master**).

To get a better understanding on how to correctly setup Sentinel, please read
the [Redis Sentinel documentation](http://redis.io/topics/sentinel) first, as
failing to configure it correctly can lead to data loss, or can bring your
whole cluster down, invalidating the failover effort.

This documentation will provide you with a minimal and a recommended topology
that can resist to some levels of failure. Usually the more Redis and Sentinel
instances you have provisioned, the better will be your availability.

The configuration consists of three parts:

- Setup Redis Master and Slave nodes
- Setup Sentinel nodes
- Setup GitLab

### Prerequisites

You need at least `3` independent machines: physical, or VMs running into
distinct physical machines. They must be believed to fail in an
independent way.

If you fail to provision the machines in that specific way, any issue with
the shared environment can bring your entire setup down.

You also need to take in consideration the underlying network topology,
making sure you have redundant connectivity between Redis / Sentinel and
GitLab instances, otherwise the networks will become a single point of
failure.

Read carefully how to configure the components below.

### Redis setup

You must have at least `3` Redis servers: `1` Master, `2` Slaves, and they
need to be each in a independent machine (see explanation above).

You can have additional Redis nodes, that will help survive a situation
where more nodes goes down. Whenever there is only `2` nodes online, a failover
will not be initiated.

As an example, if you have `6` Redis nodes, a maximum of `3` can be
simultaneously down.

Please note that there are different requirements for Sentinel nodes.
If you host them in the same Redis machines, you may need to take
that restrictions into consideration when calculating the amount of
nodes to be provisioned. See [Sentinel setup](#sentinel-setup)
documentation for more information.

All Redis nodes should be configured the same way and with similar server specs, as
in a failover situation, any **Slave** can be promoted as the new **Master** by
the Sentinel servers.

The replication requires authentication, so you need to define a password to
protect all Redis nodes and the Sentinels. They will all share the same
password, and all instances must be able to talk to
each other over the network.

Redis nodes will need the same password defined in `redis['password']` and
`redis['master_password']`, no matter if **Master** or **Slave**. At any time
during a failover the Sentinels can reconfigure a node and change it's status
from **Master** to **Slave** and vice versa.

Initial **Slave** nodes requires `redis['master']` defined to `false` and
`redis['master_ip']` pointing to the initial **Master**. If you use the
simplified configuration by enabling `redis_slave_role['enable']`, you
just need to fill in the `redis['master_ip']`.

This values doesn't have to be changed again in `/etc/gitlab/gitlab.rb` after
a failover, as the nodes will be managed by the Sentinels, and even after a
`gitlab-ctl reconfigure`, they will get their configuration restored by
the same Sentinels.

### Sentinel setup

Sentinels watches both other sentinels and Redis nodes. Whenever a Sentinel
detects that a Redis node is not responding, it will announce that to the
other sentinels. You have to reach the **quorum**, the minimum amount of
sentinels that agrees that a node is down, to be able to start a failover.

Whenever the **quorum** is met, you need the **majority** of all known
Sentinel nodes to be available and reachable, to elect the Sentinel **leader**
who will take all the decisions to restore the service availability by:

- Promoting a new **Master**
- Reconfiguring the other **Slaves** and make them point to the new **Master**
- Announce the new **Master** to every other Sentinel peer
- Reconfigure the old **Master** and demote to **Slave** when it comes back online

You must have at least `3` Redis Sentinel servers, and they need to
be each in a independent machine (that are believed to fail independently).

You can configure them in the same machines where you've configured the other
Redis servers, but understand that if a whole node goes down, you loose both
a Sentinel and a Redis instance.

The number of sentinels should ideally always be an **odd** number, for the
consensus algorithm to be effective in the case of a failure.

In a `3` nodes topology, you can only afford `1` Sentinel node going down.
Whenever the **majority** of the Sentinels goes down, the network partition
protection prevents destructive actions and a failover **will not be started**.

Here are some examples:

- With `5` or `6` sentinels, a maximum of `2` can go down for a failover begin.
- With `7` sentinels, a maximum of `3` nodes can go down.

The **Leader** election can sometimes fail the voting round when **consensus**,
is not achieved (see the odd number of nodes requirement above). In that case,
a new attempt will be made after the amount of time defined in
`sentinel['failover_timeout']` (in milliseconds).

The `failover_time` variable have a lot of different usages, according to
official documentation:

- The time needed to re-start a failover after a previous failover was
  already tried against the same master by a given Sentinel, is two
  times the failover timeout.

- The time needed for a slave replicating to a wrong master according
  to a Sentinel current configuration, to be forced to replicate
  with the right master, is exactly the failover timeout (counting since
  the moment a Sentinel detected the misconfiguration).

- The time needed to cancel a failover that is already in progress but
  did not produced any configuration change (SLAVEOF NO ONE yet not
  acknowledged by the promoted slave).

- The maximum time a failover in progress waits for all the slaves to be
  reconfigured as slaves of the new master. However even after this time
  the slaves will be reconfigured by the Sentinels anyway, but not with
  the exact parallel-syncs progression as specified.

### Recommended setup

For a minimal setup, you will install the Omnibus GitLab package in `3`
independent machines, both with **Redis** and **Sentinel**:

- Redis Master + Sentinel
- Redis Slave + Sentinel
- Redis Slave + Sentinel

Make sure you've read [Redis Setup](#redis-setup) and [Sentinel Setup](#sentinel-setup)
before, to understand how and why the amount of nodes came from.

For a recommended setup, that can resist more failures, you will install
the Omnibus GitLab package in `5` independent machines, both with
**Redis** and **Sentinel**:

- Redis Master + Sentinel
- Redis Slave + Sentinel
- Redis Slave + Sentinel
- Redis Slave + Sentinel
- Redis Slave + Sentinel

## Configuring instances using Omnibus

This is a summary of what are we going to do:

1. Provision the required number of instances specified previously
   - You can opt to install Redis and Sentinel in the same machine or each in
     independent ones.
   - Don't install Redis and Sentinel in the same machines your GitLab instance
     is running on.
   - All machines must be able to talk to each other and accept incoming
     connection over Redis (`6379`) and Sentinel (`26379`) ports.
   - GitLab machines must be able to access these machines and with the same
     permissions.
   - Protected them from indiscriminating access from external networks (Internet),
     to harden the security.

1. Download/install Omnibus GitLab using **steps 1 and 2** from
   [GitLab downloads](https://about.gitlab.com/downloads) in each node.
   - Do not complete other steps on the download page.
   - Make sure you select the correct Omnibus package, with the same version
   and type (Community, Enterprise editions) of your current install.

1. Run `touch /etc/gitlab/skip-auto-migrations` to prevent database migrations
   from running on upgrade. Only the primary GitLab application server should
   handle migrations.

1. Create/edit `/etc/gitlab/gitlab.rb` and make the changes based on the
   [Example Configurations](#example-configurations).

### Existing single-machine installation

If you already have a single-machine GitLab install running, you will need to
replicate from this machine first, before de-activating the Redis instance
inside it.

Your single-machine install will be the initial **Master**, and the `3` others
should be configured as **Slave** pointing to this machine.

After replication catches up, you will need to stop services in the
single-machine install, to rotate the **Master** to one of the new nodes.

Make the required changes in configuration and restart the new nodes again.

To disable redis in the single install, edit `/etc/gitlab/gitlab.rb`:

```ruby
redis['enable'] = false
```

If you fail to replicate first, you may loose data (unprocessed background jobs).

### Configuring Master Redis instance

You will need to configure the following in `/etc/gitlab/gitlab.rb`:

1. Define `redis_master_role['enable']` to `true`, to disable other services
   in the machine (you can still enable Sentinel)

1. Define a `redis['bind']` address pointing to a local IP that your other machines
   can reach you.
   - If you really need to bind to an external accessible IP, make
   sure you add extra firewall rules to prevent unauthorized access.
   - You can also set bind to `0.0.0.0` which listen in all interfaces.

1. Define a `redis['port']` so redis can listen for TCP requests which will
   allow other machines to connect to it.

1. Set up a password authentication with `redis['password']` and
   `redis['master_password']` (use the same password in all nodes).

Reconfigure Omnibus GitLab for the changes to take effect: `sudo gitlab-ctl reconfigure`

### Configuring Slave Redis instances

You will need to configure the following in `/etc/gitlab/gitlab.rb`:

1. Define `redis_slaves_role['enable']` to `true`, to disable other services
   in the machine (you can still enable Sentinel)
   - This will also set automatically `redis['master'] = false`.

1. Define a `redis['bind']` address pointing to a local IP that your other machines
   can reach you.
   - If you really need to bind to an external accessible IP, make
   sure you add extra firewall rules to prevent unauthorized access.
   - You can also set bind to `0.0.0.0` which listen in all interfaces.

1. Define a `redis['port']` so redis can listen for TCP requests which will
   allow other machines to connect to it.

1. Set up a password authentication with `redis['password']` and
   `redis['master_password']` (use the same password in all nodes).

1. Define `redis['master_ip']` with the IP of the **Master** Redis.

1. Define `redis['master_port']` with the port of the **Master** Redis (default to `6379`).

### Configuring Sentinel instances

Now that the Redis servers are all set up, let's configure the Sentinel
servers.

If you are not sure if your Redis servers are working and replicating
correctly, please read the [Troubleshooting Replication](#troubleshooting-replication)
and fix it before proceeding with Sentinel setup.

You must have at least `3` Redis Sentinel servers, and they need to
be each in a independent machine. You can configure them in the same
machines where you've configured the other Redis servers.

##### Community Edition

With GitLab Community Edition, you need to install, configure, execute and
monitor Sentinel from source. Omnibus GitLab Community Edition package does
not support Sentinel configuration.

See [documentation for Source Install](redis_source.md).

##### Enterprise Edition

With GitLab Enterprise Edition, you can use Omnibus package to setup multiple
machines with Sentinel daemon.

See [example configuration](#configuration-for-sentinel-ee-only) below.

### GitLab setup

The final part is to inform the main GitLab application server of the Redis
Sentinels servers and authentication credentials.

You can enable or disable Sentinel support at any time in new or existing
installations. From the GitLab application perspective, all it requires is
the correct credentials for the Sentinel nodes.

While it doesn't require a list of all Sentinel nodes, in case of a failure,
it needs to access at least one of the listed.

>**Note:**
The following steps should be performed in the [GitLab application server](gitlab.md)
which ideally should not have Redis or Sentinels in the same machine for a HA setup.

1. Edit `/etc/gitlab/gitlab.rb` and add/change the following lines:

  - `redis['master_name']` - this is the `master-group-name` from sentinel (default: `gitlab-redis`)
  - `redis['master_password']` - the same password you've defined before for Redis and Sentinels
  - `gitlab_rails['redis_sentinels']` - a list of sentinels with `host` and `port`

1. [Reconfigure] GitLab for the changes to take effect.

See [example configuration](#configuration-for-gitlab) below.

## Example Configurations

In this example we consider that all servers have an internal network
interface with IPs in the `10.0.0.x` range, and that they can connect
to each other using these IPs.

In a real world usage, you would also setup firewall rules to prevent
unauthorized access from other machines, and block traffic from the
outside (Internet).

We will use the same `3` nodes with **Redis** + **Sentinel** topology
discussed in [Redis Setup](#redis-setup) and [Sentinel Setup](#sentinel-setup)
documentation.

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

### Configuration for Redis Master

**Example configation for Redis Master:**

In `/etc/gitlab/gitlab.rb`:

```ruby
redis_master_role['enable'] = true

redis['bind'] = '10.0.0.1'
redis['port'] = 6379
redis['password'] = 'redis-password-goes-here'
redis['master_password'] = 'redis-password-goes-here'
```
Reconfigure Omnibus GitLab for the changes to take effect: `sudo gitlab-ctl reconfigure`

### Configuration for Redis Slave

**Example configation for Slave 1:**

In `/etc/gitlab/gitlab.rb`:

```ruby
redis_slave_role['enable'] = true

redis['bind'] = '10.0.0.2'
redis['port'] = 6379
redis['password'] = 'redis-password-goes-here'
redis['master_password'] = 'redis-password-goes-here'

redis['master_ip'] = '10.0.0.1' # IP of master Redis server
#redis['master_port'] = 6379 # Port of master Redis server, uncomment to change to non default
```

Reconfigure Omnibus GitLab for the changes to take effect: `sudo gitlab-ctl reconfigure`

**Example configation for Slave 2:**

In `/etc/gitlab/gitlab.rb`:

```ruby
redis_slave_role['enable'] = true

redis['bind'] = '10.0.0.3'
redis['port'] = 6379
redis['password'] = 'redis-password-goes-here'
redis['master_password'] = 'redis-password-goes-here'

redis['master_ip'] = '10.0.0.1' # IP of master Redis server
#redis['master_port'] = 6379 # Port of master Redis server, uncomment to change to non default
```

Reconfigure Omnibus GitLab for the changes to take effect: `sudo gitlab-ctl reconfigure`

### Configuration for Sentinel (EE only)

Please note that some of the variables are already configured previously
as they are required for Redis replication.

**Example configation for Sentinel 1:**

In `/etc/gitlab/gitlab.rb`:

```ruby
redis_sentinel_role['enable'] = true

redis['master_name'] = 'gitlab-redis' # must be the same in every sentinel node
redis['master_ip'] = '10.0.0.1' # ip of the initial master redis instance
#redis['master_port'] = 6379 # port of the initial master redis instance, uncomment to change to non default
redis['master_password'] = 'redis-password-goes-here' # the same value defined in redis['password'] in the master instance

## Configure Sentinel
sentinel['bind'] = '10.0.0.1'
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

**Example configation for Sentinel 2:**

In `/etc/gitlab/gitlab.rb`:

```ruby
redis_sentinel_role['enable'] = true

redis['master_name'] = 'gitlab-redis' # must be the same in every sentinel node
redis['master_ip'] = '10.0.0.1' # ip of the initial master redis instance
#redis['master_port'] = 6379 # port of the initial master redis instance, uncomment to change to non default
redis['master_password'] = 'redis-password-goes-here' # the same value defined in redis['password'] in the master instance

## Configure Sentinel
sentinel['bind'] = '10.0.0.2'
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

**Example configation for Sentinel 3:**

In `/etc/gitlab/gitlab.rb`:

```ruby
redis_sentinel_role['enable'] = true

redis['master_name'] = 'gitlab-redis' # must be the same in every sentinel node
redis['master_ip'] = '10.0.0.1' # ip of the initial master redis instance
#redis['master_port'] = 6379 # port of the initial master redis instance, uncomment to change to non default
redis['master_password'] = 'redis-password-goes-here' # the same value defined in redis['password'] in the master instance

## Configure Sentinel
sentinel['bind'] = '10.0.0.3'
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

### Control running services

In the example above we've used `redis_sentinel_role` and `redis_master_role`
which simplify the amount of configuration changes.

If you want more control, here is what each one sets for you automatically
when enabled:

```ruby
## Redis Sentinel Role
redis_sentinel_role['enable'] = true

# When Sentinel Role is enabled, the following services are enabled/disabled:
sentinel['enable'] = true

# This others are disabled:
redis['enable'] = false
bootstrap['enable'] = false
nginx['enable'] = false
postgresql['enable'] = false
gitlab_rails['enable'] = false
mailroom['enable'] = false

## Redis master/slave Role:
redis_master_role['enable'] = true # enable only one of them
redis_slave_role['enable'] = true # enable only one of them

# When Redis Master or Slave role are enabled, the following services are enabled/disabled:
# (Note that if redis and sentinel roles are combined both services will be enabled)

# When Sentinel Role is enabled, the following services are enabled/disabled:
redis['enable'] = true

# This others are disabled:
sentinel['enable'] = false
bootstrap['enable'] = false
nginx['enable'] = false
postgresql['enable'] = false
gitlab_rails['enable'] = false
mailroom['enable'] = false

# Redis Slave role also change this setting from default 'true' to 'false':
redis['master'] = false
```

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
    # port must match your master redis port, and the sleep time must be a few seconds bigger than defined one
     redis-cli -h localhost -p 6379 DEBUG sleep 20
    ```

1. Then back in the Rails console from the first step, run:

    ```
    redis.info
    ```

    You should see a different port after a few seconds delay
    (the failover/reconnect time).


## Changelog

Changes to Redis HA over time.

### Experimental Redis Sentinel support

>
Experimental Redis Sentinel support was [Introduced][ce-1877] in GitLab 8.11.
Starting with 8.14, Redis Sentinel is no longer experimental.
If you used with versions `< 8.14` before, please check the updated
documentation here.

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
