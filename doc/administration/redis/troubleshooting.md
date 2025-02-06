---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Troubleshooting Redis
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

There are a lot of moving parts that must be taken care carefully
in order for the HA setup to work as expected.

Before proceeding with the troubleshooting below, check your firewall rules:

- Redis machines
  - Accept TCP connection in `6379`
  - Connect to the other Redis machines via TCP in `6379`
- Sentinel machines
  - Accept TCP connection in `26379`
  - Connect to other Sentinel machines via TCP in `26379`
  - Connect to the Redis machines via TCP in `6379`

## Basic Redis activity check

Start Redis troubleshooting with a basic Redis activity check:

1. Open a terminal on your GitLab server.
1. Run `gitlab-redis-cli --stat` and observe the output while it runs.
1. Go to your GitLab UI and browse to a handful of pages. Any page works, such as
   group or project overviews, issues, or files in repositories.
1. Check the `stat` output again and verify that the values for `keys`, `clients`,
   `requests`, and `connections` increases as you browse. If the numbers go up,
   basic Redis functionality is working and GitLab can connect to it.

## Troubleshooting Redis replication

You can check if everything is correct by connecting to each server using
`redis-cli` application, and sending the `info replication` command as below.

```shell
/opt/gitlab/embedded/bin/redis-cli -h <redis-host-or-ip> -a '<redis-password>' info replication
```

When connected to a `Primary` Redis, you see the number of connected
`replicas`, and a list of each with connection details:

```plaintext
# Replication
role:master
connected_replicas:1
replica0:ip=10.133.5.21,port=6379,state=online,offset=208037514,lag=1
master_repl_offset:208037658
repl_backlog_active:1
repl_backlog_size:1048576
repl_backlog_first_byte_offset:206989083
repl_backlog_histlen:1048576
```

When it's a `replica`, you see details of the primary connection and if
its `up` or `down`:

```plaintext
# Replication
role:replica
master_host:10.133.1.58
master_port:6379
master_link_status:up
master_last_io_seconds_ago:1
master_sync_in_progress:0
replica_repl_offset:208096498
replica_priority:100
replica_read_only:1
connected_replicas:0
master_repl_offset:0
repl_backlog_active:0
repl_backlog_size:1048576
repl_backlog_first_byte_offset:0
repl_backlog_histlen:0
```

## High CPU usage on Redis instance

By default, GitLab uses over 600 Sidekiq queues, each stored as a Redis list. Each Sidekiq thread issues a `BRPOP` command with all the queues listed in a long string.
Redis CPU utilization grows as the number of queues and the rate of `BRPOP` calls increases. If your GitLab instance has many Sidekiq processes, this can cause Redis
CPU utilization to approach 100%. High CPU utilization degrades GitLab performance significantly.

To reduce CPU usage on Redis caused by Sidekiq you can both:

- Use [routing rules](../sidekiq/processing_specific_job_classes.md#routing-rules) to reduce the number of Sidekiq queues.
- If you are using GitLab 16.6 and earlier, increase the [`SIDEKIQ_SEMI_RELIABLE_FETCH_TIMEOUT` environment variable](../environment_variables.md) to improve CPU usage on Redis.
  On GitLab 16.7 and later, the [default value is 5](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/139583), which should be sufficient.

The `SIDEKIQ_SEMI_RELIABLE_FETCH_TIMEOUT` option reduces the overhead that tearing down and connecting causes, but increase the shutdown delay of Sidekiq.

## Troubleshooting Sentinel

If you get an error like: `Redis::CannotConnectError: No sentinels available.`,
there may be something wrong with your configuration files or it can be related
to [this issue](https://github.com/redis/redis-rb/issues/531).

You must make sure you are defining the same value in `redis['master_name']`
and `redis['master_password']` as you defined for your sentinel node.

The way the Redis connector `redis-rb` works with sentinel is a bit
non-intuitive. We try to hide the complexity in the Linux package, but it still requires
a few extra configurations.

To make sure your configuration is correct:

1. SSH into your GitLab application server
1. Enter the Rails console:

   ```shell
   # For Omnibus installations
   sudo gitlab-rails console

   # For source installations
   sudo -u git rails console -e production
   ```

1. Run in the console:

   ```ruby
   redis = Gitlab::Redis::SharedState.redis
   redis.info
   ```

   Keep this screen open, and proceed to trigger a failover as described below.

1. To trigger a failover on the primary Redis, SSH into the Redis server and run:

   ```shell
   # port must match your primary redis port, and the sleep time must be a few seconds bigger than defined one
    redis-cli -h localhost -p 6379 DEBUG sleep 20
   ```

   WARNING:
   This action affects services, and takes the instance down for up to 20 seconds. If successful,
   it should recover after that.

1. Then back in the Rails console from the first step, run:

   ```ruby
   redis.info
   ```

   You should see a different port after a few seconds delay
   (the failover/reconnect time).

## Troubleshooting a non-bundled Redis with a self-compiled installation

If you get an error in GitLab like `Redis::CannotConnectError: No sentinels available.`,
there may be something wrong with your configuration files or it can be related
to [this upstream issue](https://github.com/redis/redis-rb/issues/531).

You must make sure that `resque.yml` and `sentinel.conf` are configured correctly,
otherwise `redis-rb` does not work properly.

The `master-group-name` (`gitlab-redis`) defined in (`sentinel.conf`)
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
      port: 26379  # point to sentinel, not to redis port
    -
      host: 10.0.0.2
      port: 26379  # point to sentinel, not to redis port
    -
      host: 10.0.0.3
      port: 26379  # point to sentinel, not to redis port
```

When in doubt, read the [Redis Sentinel](https://redis.io/docs/latest/operate/oss_and_stack/management/sentinel/) documentation.
