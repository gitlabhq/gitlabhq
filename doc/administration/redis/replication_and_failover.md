---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Redis replication and failover with the Linux package
---

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab Self-Managed

This documentation is for the Linux package. To use your own
non-bundled Redis, see [Redis replication and failover providing your own instance](replication_and_failover_external.md).

In Redis lingo, `primary` is called `master`. In this document, `primary` is used
instead of `master`, except the settings where `master` is required.

Using [Redis](https://redis.io/) in scalable environment is possible using a **Primary** x **Replica**
topology with a [Redis Sentinel](https://redis.io/docs/latest/operate/oss_and_stack/management/sentinel/) service to watch and automatically
start the failover procedure.

Redis requires authentication if used with Sentinel. See
[Redis Security](https://redis.io/docs/latest/operate/rc/security/) documentation for more
information. We recommend using a combination of a Redis password and tight
firewall rules to secure your Redis service.
You are highly encouraged to read the [Redis Sentinel](https://redis.io/docs/latest/operate/oss_and_stack/management/sentinel/) documentation
before configuring Redis with GitLab to fully understand the topology and
architecture.

Before diving into the details of setting up Redis and Redis Sentinel for a
replicated topology, make sure you read this document once as a whole to better
understand how the components are tied together.

You need at least `3` independent machines: physical, or VMs running into
distinct physical machines. It is essential that all primary and replica Redis
instances run in different machines. If you fail to provision the machines in
that specific way, any issue with the shared environment can bring your entire
setup down.

It is OK to run a Sentinel alongside of a primary or replica Redis instance.
There should be no more than one Sentinel on the same machine though.

You also need to take into consideration the underlying network topology,
making sure you have redundant connectivity between Redis / Sentinel and
GitLab instances, otherwise the networks become a single point of
failure.

Running Redis in a scaled environment requires a few things:

- Multiple Redis instances
- Run Redis in a **Primary** x **Replica** topology
- Multiple Sentinel instances
- Application support and visibility to all Sentinel and Redis instances

Redis Sentinel can handle the most important tasks in an HA environment and that's
to help keep servers online with minimal to no downtime. Redis Sentinel:

- Monitors **Primary** and **Replicas** instances to see if they are available
- Promotes a **Replica** to **Primary** when the **Primary** fails
- Demotes a **Primary** to **Replica** when the failed **Primary** comes back online
  (to prevent data-partitioning)
- Can be queried by the application to always connect to the current **Primary**
  server

When a **Primary** fails to respond, it's the application's responsibility
(in our case GitLab) to handle timeout and reconnect (querying a **Sentinel**
for a new **Primary**).

To get a better understanding on how to correctly set up Sentinel, read
the [Redis Sentinel](https://redis.io/docs/latest/operate/oss_and_stack/management/sentinel/) documentation first, as
failing to configure it correctly can lead to data loss or can bring your
whole cluster down, invalidating the failover effort.

## Recommended setup

For a minimal setup, you need to install the Linux package in `3`
**independent** machines, both with **Redis** and **Sentinel**:

- Redis Primary + Sentinel
- Redis Replica + Sentinel
- Redis Replica + Sentinel

If you are not sure or don't understand why and where the amount of nodes come
from, read [Redis setup overview](#redis-setup-overview) and
[Sentinel setup overview](#sentinel-setup-overview).

For a recommended setup that can resist more failures, you need to install
the Linux package in `5` **independent** machines, both with
**Redis** and **Sentinel**:

- Redis Primary + Sentinel
- Redis Replica + Sentinel
- Redis Replica + Sentinel
- Redis Replica + Sentinel
- Redis Replica + Sentinel

### Redis setup overview

You must have at least `3` Redis servers: `1` primary, `2` Replicas, and they
need to each be on independent machines (see explanation above).

You can have additional Redis nodes, that helps to survive a situation
where more nodes goes down. Whenever there is only `2` nodes online, a failover
is not initiated.

As an example, if you have `6` Redis nodes, a maximum of `3` can be
simultaneously down.

There are different requirements for Sentinel nodes.
If you host them in the same Redis machines, you may need to take
that restrictions into consideration when calculating the amount of
nodes to be provisioned. See [Sentinel setup overview](#sentinel-setup-overview)
documentation for more information.

All Redis nodes should be configured the same way and with similar server specs, as
in a failover situation, any **Replica** can be promoted as the new **Primary** by
the Sentinel servers.

The replication requires authentication, so you need to define a password to
protect all Redis nodes and the Sentinels. All of them share the same
password, and all instances must be able to talk to
each other over the network.

### Sentinel setup overview

Sentinels watch both other Sentinels and Redis nodes. Whenever a Sentinel
detects that a Redis node isn't responding, it announces the node's status to
the other Sentinels. The Sentinels have to reach a _quorum_ (the minimum amount
of Sentinels agreeing a node is down) to be able to start a failover.

Whenever the **quorum** is met, the **majority** of all known Sentinel nodes
need to be available and reachable, so that they can elect the Sentinel **leader**
who takes all the decisions to restore the service availability by:

- Promoting a new **Primary**
- Reconfiguring the other **Replicas** and make them point to the new **Primary**
- Announce the new **Primary** to every other Sentinel peer
- Reconfigure the old **Primary** and demote to **Replica** when it comes back online

You must have at least `3` Redis Sentinel servers, and they need to
be each in an independent machine (that are believed to fail independently),
ideally in different geographical areas.

You can configure them in the same machines where you've configured the other
Redis servers, but understand that if a whole node goes down, you loose both
a Sentinel and a Redis instance.

The number of sentinels should ideally always be an **odd** number, for the
consensus algorithm to be effective in the case of a failure.

In a `3` nodes topology, you can only afford `1` Sentinel node going down.
Whenever the **majority** of the Sentinels goes down, the network partition
protection prevents destructive actions and a failover **is not started**.

Here are some examples:

- With `5` or `6` sentinels, a maximum of `2` can go down for a failover begin.
- With `7` sentinels, a maximum of `3` nodes can go down.

The **Leader** election can sometimes fail the voting round when **consensus**
is not achieved (see the odd number of nodes requirement above). In that case,
a new attempt is made after the amount of time defined in
`sentinel['failover_timeout']` (in milliseconds).

NOTE:
We can see where `sentinel['failover_timeout']` is defined later.

The `failover_timeout` variable has a lot of different use cases. According to
the official documentation:

- The time needed to re-start a failover after a previous failover was
  already tried against the same primary by a given Sentinel, is two
  times the failover timeout.

- The time needed for a replica replicating to a wrong primary according
  to a Sentinel current configuration, to be forced to replicate
  with the right primary, is exactly the failover timeout (counting since
  the moment a Sentinel detected the misconfiguration).

- The time needed to cancel a failover that is already in progress but
  did not produced any configuration change (REPLICAOF NO ONE yet not
  acknowledged by the promoted replica).

- The maximum time a failover in progress waits for all the replicas to be
  reconfigured as replicas of the new primary. However even after this time
  the replicas are reconfigured by the Sentinels anyway, but not with
  the exact parallel-syncs progression as specified.

## Configuring Redis

This is the section where we install and set up the new Redis instances.

It is assumed that you have installed GitLab and all its components from scratch.
If you already have Redis installed and running, read how to
[switch from a single-machine installation](#switching-from-an-existing-single-machine-installation).

NOTE:
Redis nodes (both primary and replica) need the same password defined in
`redis['password']`. At any time during a failover the Sentinels can
reconfigure a node and change its status from primary to replica and vice versa.

### Requirements

The requirements for a Redis setup are the following:

1. Provision the minimum required number of instances as specified in the
   [recommended setup](#recommended-setup) section.
1. We **Do not** recommend installing Redis or Redis Sentinel in the same machines your
   GitLab application is running on as this weakens your HA configuration. You can however opt in to install Redis
   and Sentinel in the same machine.
1. All Redis nodes must be able to talk to each other and accept incoming
   connections over Redis (`6379`) and Sentinel (`26379`) ports (unless you
   change the default ones).
1. The server that hosts the GitLab application must be able to access the
   Redis nodes.
1. Protect the nodes from access from external networks ([Internet](https://gitlab.com/gitlab-org/gitlab-foss/uploads/c4cc8cd353604bd80315f9384035ff9e/The_Internet_IT_Crowd.png)), using
   firewall.

### Switching from an existing single-machine installation

If you already have a single-machine GitLab install running, you need to
replicate from this machine first, before de-activating the Redis instance
inside it.

Your single-machine install is the initial **Primary**, and the `3` others
should be configured as **Replica** pointing to this machine.

After replication catches up, you need to stop services in the
single-machine install, to rotate the **Primary** to one of the new nodes.

Make the required changes in configuration and restart the new nodes again.

To disable Redis in the single install, edit `/etc/gitlab/gitlab.rb`:

```ruby
redis['enable'] = false
```

If you fail to replicate first, you may loose data (unprocessed background jobs).

### Step 1. Configuring the primary Redis instance

1. SSH into the **Primary** Redis server.
1. [Download and install](https://about.gitlab.com/install/) the Linux
   package you want using **steps 1 and 2** from the GitLab downloads page.
   - Make sure you select the correct Linux package, with the same version
     and type (Community, Enterprise editions) of your current install.
   - Do not complete any other steps on the download page.

1. Edit `/etc/gitlab/gitlab.rb` and add the contents:

   ```ruby
   # Specify server role as 'redis_master_role'
   roles ['redis_master_role']

   # IP address pointing to a local IP that the other machines can reach to.
   # You can also set bind to '0.0.0.0' which listen in all interfaces.
   # If you really need to bind to an external accessible IP, make
   # sure you add extra firewall rules to prevent unauthorized access.
   redis['bind'] = '10.0.0.1'

   # Define a port so Redis can listen for TCP requests which allows other
   # machines to connect to it.
   redis['port'] = 6379

   # Set up password authentication for Redis (use the same password in all nodes).
   redis['password'] = 'redis-password-goes-here'
   ```

1. Only the primary GitLab application server should handle migrations. To
   prevent database migrations from running on upgrade, add the following
   configuration to your `/etc/gitlab/gitlab.rb` file:

   ```ruby
   gitlab_rails['auto_migrate'] = false
   ```

1. [Reconfigure GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation) for the changes to take effect.

NOTE:
You can specify multiple roles like sentinel and Redis as:
`roles ['redis_sentinel_role', 'redis_master_role']`.
Read more about [roles](https://docs.gitlab.com/omnibus/roles/).

### Step 2. Configuring the replica Redis instances

1. SSH into the **replica** Redis server.
1. [Download and install](https://about.gitlab.com/install/) the Linux
   package you want using **steps 1 and 2** from the GitLab downloads page.
   - Make sure you select the correct Linux package, with the same version
     and type (Community, Enterprise editions) of your current install.
   - Do not complete any other steps on the download page.

1. Edit `/etc/gitlab/gitlab.rb` and add the contents:

   ```ruby
   # Specify server role as 'redis_replica_role'
   roles ['redis_replica_role']

   # IP address pointing to a local IP that the other machines can reach to.
   # You can also set bind to '0.0.0.0' which listen in all interfaces.
   # If you really need to bind to an external accessible IP, make
   # sure you add extra firewall rules to prevent unauthorized access.
   redis['bind'] = '10.0.0.2'

   # Define a port so Redis can listen for TCP requests which allows other
   # machines to connect to it.
   redis['port'] = 6379

   # The same password for Redis authentication you set up for the primary node.
   redis['password'] = 'redis-password-goes-here'

   # The IP of the primary Redis node.
   redis['master_ip'] = '10.0.0.1'

   # Port of primary Redis server, uncomment to change to non default. Defaults
   # to `6379`.
   #redis['master_port'] = 6379
   ```

1. To prevent reconfigure from running automatically on upgrade, run:

   ```shell
   sudo touch /etc/gitlab/skip-auto-reconfigure
   ```

1. Only the primary GitLab application server should handle migrations. To
   prevent database migrations from running on upgrade, add the following
   configuration to your `/etc/gitlab/gitlab.rb` file:

   ```ruby
   gitlab_rails['auto_migrate'] = false
   ```

1. [Reconfigure GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation) for the changes to take effect.
1. Go through the steps again for all the other replica nodes.

NOTE:
You can specify multiple roles like sentinel and Redis as:
`roles ['redis_sentinel_role', 'redis_master_role']`.
Read more about [roles](https://docs.gitlab.com/omnibus/roles/).

These values don't have to be changed again in `/etc/gitlab/gitlab.rb` after
a failover, as the nodes are managed by the Sentinels, and even after a
`gitlab-ctl reconfigure`, they get their configuration restored by
the same Sentinels.

### Step 3. Configuring the Redis Sentinel instances

NOTE:
[Support for Sentinel password authentication](https://gitlab.com/gitlab-org/gitlab/-/issues/235938) was introduced in GitLab 16.1.

Now that the Redis servers are all set up, let's configure the Sentinel
servers.

If you are not sure if your Redis servers are working and replicating
correctly, read the [Troubleshooting Replication](troubleshooting.md#troubleshooting-redis-replication)
and fix it before proceeding with Sentinel setup.

You must have at least `3` Redis Sentinel servers, and they need to
be each in an independent machine. You can configure them in the same
machines where you've configured the other Redis servers.

With GitLab Enterprise Edition, you can use the Linux package to set up
multiple machines with the Sentinel daemon.

1. SSH into the server that hosts Redis Sentinel.
1. **You can omit this step if the Sentinels is hosted in the same node as
   the other Redis instances.**

   [Download and install](https://about.gitlab.com/install/) the
   Linux Enterprise Edition package using **steps 1 and 2** from the
   GitLab downloads page.
   - Make sure you select the correct Linux package, with the same version
     the GitLab application is running.
   - Do not complete any other steps on the download page.

1. Edit `/etc/gitlab/gitlab.rb` and add the contents (if you are installing the
   Sentinels in the same node as the other Redis instances, some values might
   be duplicate below):

   ```ruby
   roles ['redis_sentinel_role']

   # Must be the same in every sentinel node
   redis['master_name'] = 'gitlab-redis'

   # The same password for Redis authentication you set up for the primary node.
   redis['master_password'] = 'redis-password-goes-here'

   # The IP of the primary Redis node.
   redis['master_ip'] = '10.0.0.1'

   # Define a port so Redis can listen for TCP requests which allows other
   # machines to connect to it.
   redis['port'] = 6379

   # Port of primary Redis server, uncomment to change to non default. Defaults
   # to `6379`.
   #redis['master_port'] = 6379

   ## Configure Sentinel
   sentinel['bind'] = '10.0.0.1'

   ## Optional password for Sentinel authentication. Defaults to no password required.
   # sentinel['password'] = 'sentinel-password-goes here'

   # Port that Sentinel listens on, uncomment to change to non default. Defaults
   # to `26379`.
   # sentinel['port'] = 26379

   ## Quorum must reflect the amount of voting sentinels it take to start a failover.
   ## Value must NOT be greater then the amount of sentinels.
   ##
   ## The quorum can be used to tune Sentinel in two ways:
   ## 1. If a the quorum is set to a value smaller than the majority of Sentinels
   ##    we deploy, we are basically making Sentinel more sensible to primary failures,
   ##    triggering a failover as soon as even just a minority of Sentinels is no longer
   ##    able to talk with the primary.
   ## 1. If a quorum is set to a value greater than the majority of Sentinels, we are
   ##    making Sentinel able to failover only when there are a very large number (larger
   ##    than majority) of well connected Sentinels which agree about the primary being down.s
   sentinel['quorum'] = 2

   ## Consider unresponsive server down after x amount of ms.
   # sentinel['down_after_milliseconds'] = 10000

   ## Specifies the failover timeout in milliseconds. It is used in many ways:
   ##
   ## - The time needed to re-start a failover after a previous failover was
   ##   already tried against the same primary by a given Sentinel, is two
   ##   times the failover timeout.
   ##
   ## - The time needed for a replica replicating to a wrong primary according
   ##   to a Sentinel current configuration, to be forced to replicate
   ##   with the right primary, is exactly the failover timeout (counting since
   ##   the moment a Sentinel detected the misconfiguration).
   ##
   ## - The time needed to cancel a failover that is already in progress but
   ##   did not produced any configuration change (REPLICAOF NO ONE yet not
   ##   acknowledged by the promoted replica).
   ##
   ## - The maximum time a failover in progress waits for all the replica to be
   ##   reconfigured as replicas of the new primary. However even after this time
   ##   the replicas are reconfigured by the Sentinels anyway, but not with
   ##   the exact parallel-syncs progression as specified.
   # sentinel['failover_timeout'] = 60000
   ```

1. To prevent database migrations from running on upgrade, run:

   ```shell
   sudo touch /etc/gitlab/skip-auto-reconfigure
   ```

   Only the primary GitLab application server should handle migrations.

1. [Reconfigure GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation) for the changes to take effect.
1. Go through the steps again for all the other Sentinel nodes.

### Step 4. Configuring the GitLab application

The final part is to inform the main GitLab application server of the Redis
Sentinels servers and authentication credentials.

You can enable or disable Sentinel support at any time in new or existing
installations. From the GitLab application perspective, all it requires is
the correct credentials for the Sentinel nodes.

While it doesn't require a list of all Sentinel nodes, in case of a failure,
it needs to access at least one of the listed.

NOTE:
The following steps should be performed in the GitLab application server
which ideally should not have Redis or Sentinels on it for a HA setup.

1. SSH into the server where the GitLab application is installed.
1. Edit `/etc/gitlab/gitlab.rb` and add/change the following lines:

   ```ruby
   ## Must be the same in every sentinel node
   redis['master_name'] = 'gitlab-redis'

   ## The same password for Redis authentication you set up for the primary node.
   redis['master_password'] = 'redis-password-goes-here'

   ## A list of sentinels with `host` and `port`
   gitlab_rails['redis_sentinels'] = [
     {'host' => '10.0.0.1', 'port' => 26379},
     {'host' => '10.0.0.2', 'port' => 26379},
     {'host' => '10.0.0.3', 'port' => 26379}
   ]
   # gitlab_rails['redis_sentinels_password'] = 'sentinel-password-goes-here' # uncomment and set it to the same value as in sentinel['password']
   ```

1. [Reconfigure GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation) for the changes to take effect.

### Step 5. Enable Monitoring

If you enable Monitoring, it must be enabled on **all** Redis servers.

1. Make sure to collect [`CONSUL_SERVER_NODES`](../postgresql/replication_and_failover.md#consul-information), which are the IP addresses or DNS records of the Consul server nodes, for the next step. Note they are presented as `Y.Y.Y.Y consul1.gitlab.example.com Z.Z.Z.Z`

1. Create/edit `/etc/gitlab/gitlab.rb` and add the following configuration:

   ```ruby
   # Enable service discovery for Prometheus
   consul['enable'] = true
   consul['monitoring_service_discovery'] =  true

   # Replace placeholders
   # Y.Y.Y.Y consul1.gitlab.example.com Z.Z.Z.Z
   # with the addresses of the Consul server nodes
   consul['configuration'] = {
      retry_join: %w(Y.Y.Y.Y consul1.gitlab.example.com Z.Z.Z.Z),
   }

   # Set the network addresses that the exporters listen on
   node_exporter['listen_address'] = '0.0.0.0:9100'
   redis_exporter['listen_address'] = '0.0.0.0:9121'
   ```

1. Run `sudo gitlab-ctl reconfigure` to compile the configuration.

## Example of a minimal configuration with 1 primary, 2 replicas and 3 Sentinels

In this example we consider that all servers have an internal network
interface with IPs in the `10.0.0.x` range, and that they can connect
to each other using these IPs.

In a real world usage, you would also set up firewall rules to prevent
unauthorized access from other machines and block traffic from the
outside (Internet).

We use the same `3` nodes with **Redis** + **Sentinel** topology
discussed in [Redis setup overview](#redis-setup-overview) and
[Sentinel setup overview](#sentinel-setup-overview) documentation.

Here is a list and description of each **machine** and the assigned **IP**:

- `10.0.0.1`: Redis primary + Sentinel 1
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

In `/etc/gitlab/gitlab.rb`:

```ruby
roles ['redis_sentinel_role', 'redis_master_role']
redis['bind'] = '10.0.0.1'
redis['port'] = 6379
redis['password'] = 'redis-password-goes-here'
redis['master_name'] = 'gitlab-redis' # must be the same in every sentinel node
redis['master_password'] = 'redis-password-goes-here' # the same value defined in redis['password'] in the primary instance
redis['master_ip'] = '10.0.0.1' # ip of the initial primary redis instance
#redis['master_port'] = 6379 # port of the initial primary redis instance, uncomment to change to non default
sentinel['bind'] = '10.0.0.1'
# sentinel['password'] = 'sentinel-password-goes-here' # must be the same in every sentinel node, uncomment to set a password
# sentinel['port'] = 26379 # uncomment to change default port
sentinel['quorum'] = 2
# sentinel['down_after_milliseconds'] = 10000
# sentinel['failover_timeout'] = 60000
```

[Reconfigure GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation) for the changes to take effect.

### Example configuration for Redis replica 1 and Sentinel 2

In `/etc/gitlab/gitlab.rb`:

```ruby
roles ['redis_sentinel_role', 'redis_replica_role']
redis['bind'] = '10.0.0.2'
redis['port'] = 6379
redis['password'] = 'redis-password-goes-here'
redis['master_password'] = 'redis-password-goes-here'
redis['master_ip'] = '10.0.0.1' # IP of primary Redis server
#redis['master_port'] = 6379 # Port of primary Redis server, uncomment to change to non default
redis['master_name'] = 'gitlab-redis' # must be the same in every sentinel node
sentinel['bind'] = '10.0.0.2'
# sentinel['password'] = 'sentinel-password-goes-here' # must be the same in every sentinel node, uncomment to set a password
# sentinel['port'] = 26379 # uncomment to change default port
sentinel['quorum'] = 2
# sentinel['down_after_milliseconds'] = 10000
# sentinel['failover_timeout'] = 60000
```

[Reconfigure GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation) for the changes to take effect.

### Example configuration for Redis replica 2 and Sentinel 3

In `/etc/gitlab/gitlab.rb`:

```ruby
roles ['redis_sentinel_role', 'redis_replica_role']
redis['bind'] = '10.0.0.3'
redis['port'] = 6379
redis['password'] = 'redis-password-goes-here'
redis['master_password'] = 'redis-password-goes-here'
redis['master_ip'] = '10.0.0.1' # IP of primary Redis server
#redis['master_port'] = 6379 # Port of primary Redis server, uncomment to change to non default
redis['master_name'] = 'gitlab-redis' # must be the same in every sentinel node
sentinel['bind'] = '10.0.0.3'
# sentinel['password'] = 'sentinel-password-goes-here' # must be the same in every sentinel node, uncomment to set a password
# sentinel['port'] = 26379 # uncomment to change default port
sentinel['quorum'] = 2
# sentinel['down_after_milliseconds'] = 10000
# sentinel['failover_timeout'] = 60000
```

[Reconfigure GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation) for the changes to take effect.

### Example configuration for the GitLab application

In `/etc/gitlab/gitlab.rb`:

```ruby
redis['master_name'] = 'gitlab-redis'
redis['master_password'] = 'redis-password-goes-here'
gitlab_rails['redis_sentinels'] = [
  {'host' => '10.0.0.1', 'port' => 26379},
  {'host' => '10.0.0.2', 'port' => 26379},
  {'host' => '10.0.0.3', 'port' => 26379}
]
# gitlab_rails['redis_sentinels_password'] = 'sentinel-password-goes-here' # uncomment and set it to the same value as in sentinel['password']
```

[Reconfigure GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation) for the changes to take effect.

## Advanced configuration

This section covers configuration options that go beyond the recommended and minimal configurations.

### Running multiple Redis clusters

The Linux package supports running separate Redis and Sentinel instances for different
persistence classes.

| Class              | Purpose |
|--------------------|---------|
| `cache`            | Store cached data. |
| `queues`           | Store Sidekiq background jobs. |
| `shared_state`     | Store session-related and other persistent data. |
| `actioncable`      | Pub/Sub queue backend for ActionCable. |
| `trace_chunks`     | Store [CI trace chunks](../cicd/job_logs.md#enable-or-disable-incremental-logging) data. |
| `rate_limiting`    | Store [rate limiting](../settings/user_and_ip_rate_limits.md) state. |
| `sessions`         | Store [sessions](../../development/session.md#gitlabsession). |
| `repository_cache` | Store cache data specific to repositories. |

To make this work with Sentinel:

1. [Configure the different Redis/Sentinels](#configuring-redis) instances based on your needs.
1. For each Rails application instance, edit its `/etc/gitlab/gitlab.rb` file:

   ```ruby
   gitlab_rails['redis_cache_instance'] = REDIS_CACHE_URL
   gitlab_rails['redis_queues_instance'] = REDIS_QUEUES_URL
   gitlab_rails['redis_shared_state_instance'] = REDIS_SHARED_STATE_URL
   gitlab_rails['redis_actioncable_instance'] = REDIS_ACTIONCABLE_URL
   gitlab_rails['redis_trace_chunks_instance'] = REDIS_TRACE_CHUNKS_URL
   gitlab_rails['redis_rate_limiting_instance'] = REDIS_RATE_LIMITING_URL
   gitlab_rails['redis_sessions_instance'] = REDIS_SESSIONS_URL
   gitlab_rails['redis_repository_cache_instance'] = REDIS_REPOSITORY_CACHE_URL

   # Configure the Sentinels
   gitlab_rails['redis_cache_sentinels'] = [
     { host: REDIS_CACHE_SENTINEL_HOST, port: 26379 },
     { host: REDIS_CACHE_SENTINEL_HOST2, port: 26379 }
   ]
   gitlab_rails['redis_queues_sentinels'] = [
     { host: REDIS_QUEUES_SENTINEL_HOST, port: 26379 },
     { host: REDIS_QUEUES_SENTINEL_HOST2, port: 26379 }
   ]
   gitlab_rails['redis_shared_state_sentinels'] = [
     { host: SHARED_STATE_SENTINEL_HOST, port: 26379 },
     { host: SHARED_STATE_SENTINEL_HOST2, port: 26379 }
   ]
   gitlab_rails['redis_actioncable_sentinels'] = [
     { host: ACTIONCABLE_SENTINEL_HOST, port: 26379 },
     { host: ACTIONCABLE_SENTINEL_HOST2, port: 26379 }
   ]
   gitlab_rails['redis_trace_chunks_sentinels'] = [
     { host: TRACE_CHUNKS_SENTINEL_HOST, port: 26379 },
     { host: TRACE_CHUNKS_SENTINEL_HOST2, port: 26379 }
   ]
   gitlab_rails['redis_rate_limiting_sentinels'] = [
     { host: RATE_LIMITING_SENTINEL_HOST, port: 26379 },
     { host: RATE_LIMITING_SENTINEL_HOST2, port: 26379 }
   ]
   gitlab_rails['redis_sessions_sentinels'] = [
     { host: SESSIONS_SENTINEL_HOST, port: 26379 },
     { host: SESSIONS_SENTINEL_HOST2, port: 26379 }
   ]
   gitlab_rails['redis_repository_cache_sentinels'] = [
     { host: REPOSITORY_CACHE_SENTINEL_HOST, port: 26379 },
     { host: REPOSITORY_CACHE_SENTINEL_HOST2, port: 26379 }
   ]

   # gitlab_rails['redis_cache_sentinels_password'] = 'sentinel-password-goes-here'
   # gitlab_rails['redis_queues_sentinels_password'] = 'sentinel-password-goes-here'
   # gitlab_rails['redis_shared_state_sentinels_password'] = 'sentinel-password-goes-here'
   # gitlab_rails['redis_actioncable_sentinels_password'] = 'sentinel-password-goes-here'
   # gitlab_rails['redis_trace_chunks_sentinels_password'] = 'sentinel-password-goes-here'
   # gitlab_rails['redis_rate_limiting_sentinels_password'] = 'sentinel-password-goes-here'
   # gitlab_rails['redis_sessions_sentinels_password'] = 'sentinel-password-goes-here'
   # gitlab_rails['redis_repository_cache_sentinels_password'] = 'sentinel-password-goes-here'
   ```

   - Redis URLs should be in the format: `redis://:PASSWORD@SENTINEL_PRIMARY_NAME`, where:
     - `PASSWORD` is the plaintext password for the Redis instance.
     - `SENTINEL_PRIMARY_NAME` is the Sentinel primary name set with `redis['master_name']`,
       for example `gitlab-redis-cache`.

1. Save the file and reconfigure GitLab for the change to take effect:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

NOTE:
For each persistence class, GitLab defaults to using the
configuration specified in `gitlab_rails['redis_sentinels']` unless
overridden by the previously described settings.

### Control running services

In the previous example, we've used `redis_sentinel_role` and
`redis_master_role` which simplifies the amount of configuration changes.

If you want more control, here is what each one sets for you automatically
when enabled:

```ruby
## Redis Sentinel Role
redis_sentinel_role['enable'] = true

# When Sentinel Role is enabled, the following services are also enabled
sentinel['enable'] = true

# The following services are disabled
redis['enable'] = false
bootstrap['enable'] = false
nginx['enable'] = false
postgresql['enable'] = false
gitlab_rails['enable'] = false
mailroom['enable'] = false

-------

## Redis primary/replica Role
redis_master_role['enable'] = true # enable only one of them
redis_replica_role['enable'] = true # enable only one of them

# When Redis primary or Replica role are enabled, the following services are
# enabled/disabled. If Redis and Sentinel roles are combined, both
# services are enabled.

# The following services are disabled
sentinel['enable'] = false
bootstrap['enable'] = false
nginx['enable'] = false
postgresql['enable'] = false
gitlab_rails['enable'] = false
mailroom['enable'] = false

# For Redis Replica role, also change this setting from default 'true' to 'false':
redis['master'] = false
```

You can find the relevant attributes defined in [`gitlab_rails.rb`](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/files/gitlab-cookbooks/gitlab/libraries/gitlab_rails.rb).

### Control startup behavior

> - [Introduced](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/6646) in GitLab 15.10.

To prevent the bundled Redis service from starting at boot or restarting after changing its configuration:

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   redis['start_down'] = true
   ```

1. Reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

If you need to test a new replica node, you may set `start_down` to
`true` and manually start the node. After the new replica node is confirmed
working in the Redis cluster, set `start_down` to `false` and reconfigure GitLab
to ensure the node starts and restarts as expected during operation.

### Control replica configuration

> - [Introduced](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/6646) in GitLab 15.10.

To prevent the `replicaof` line from rendering in the Redis configuration file:

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   redis['set_replicaof'] = false
   ```

1. Reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

This setting can be used to prevent replication of a Redis node independently of other Redis settings.

## Troubleshooting

See the [Redis troubleshooting guide](troubleshooting.md).

## Further reading

Read more:

1. [Reference architectures](../reference_architectures/_index.md)
1. [Configure the database](../postgresql/replication_and_failover.md)
1. [Configure NFS](../nfs.md)
1. [Configure the load balancers](../load_balancer.md)
