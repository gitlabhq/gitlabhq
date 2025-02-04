---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Redis development guidelines
---

## Redis instances

GitLab uses [Redis](https://redis.io) for the following distinct purposes:

- Caching (mostly via `Rails.cache`).
- As a job processing queue with [Sidekiq](sidekiq/_index.md).
- To manage the shared application state.
- To store CI trace chunks.
- As a Pub/Sub queue backend for ActionCable.
- Rate limiting state storage.
- Sessions.

In most environments (including the GDK), all of these point to the same
Redis instance.

On GitLab.com, we use [separate Redis instances](../administration/redis/replication_and_failover.md#running-multiple-redis-clusters).
See the [Redis SRE guide](https://gitlab.com/gitlab-com/runbooks/-/blob/master/docs/redis/redis-survival-guide-for-sres.md)
for more details on our setup.

Every application process is configured to use the same Redis servers, so they
can be used for inter-process communication in cases where [PostgreSQL](sql.md)
is less appropriate. For example, transient state or data that is written much
more often than it is read.

If [Geo](geo.md) is enabled, each Geo site gets its own, independent Redis
database.

We have [development documentation on adding a new Redis instance](redis/new_redis_instance.md).

## Key naming

Redis is a flat namespace with no hierarchy, which means we must pay attention
to key names to avoid collisions. Typically we use colon-separated elements to
provide a semblance of structure at application level. An example might be
`projects:1:somekey`.

Although we split our Redis usage by purpose into distinct categories, and
those may map to separate Redis servers in a Highly Available
configuration like GitLab.com, the default Omnibus and GDK setups share
a single Redis server. This means that keys should **always** be
globally unique across all categories.

It is usually better to use immutable identifiers - project ID rather than
full path, for instance - in Redis key names. If full path is used, the key
stops being consulted if the project is renamed. If the contents of the key are
invalidated by a name change, it is better to include a hook that expires
the entry, instead of relying on the key changing.

### Multi-key commands

GitLab supports Redis Cluster for [cache-related workloads](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/redis/cache.rb) type, introduced in [epic 878](https://gitlab.com/groups/gitlab-com/gl-infra/-/epics/878).

This imposes an additional constraint on naming: where GitLab is performing
operations that require several keys to be held on the same Redis server - for
instance, diffing two sets held in Redis - the keys should ensure that by
enclosing the changeable parts in curly braces.
For example:

```plaintext
project:{1}:set_a
project:{1}:set_b
project:{2}:set_c
```

`set_a` and `set_b` are guaranteed to be held on the same Redis server, while `set_c` is not.

Currently, we validate this in the development and test environments
with the [`RedisClusterValidator`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/instrumentation/redis_cluster_validator.rb),
which is enabled for the `cache` and `shared_state`
[Redis instances](https://docs.gitlab.com/omnibus/settings/redis.html#running-with-multiple-redis-instances)..

Developers are highly encouraged to use [hash-tags](https://redis.io/docs/latest/operate/oss_and_stack/reference/cluster-spec/#hash-tags)
where appropriate to facilitate future adoption of Redis Cluster in more Redis types. For example, the Namespace model uses hash-tags
for its [config cache keys](https://gitlab.com/gitlab-org/gitlab/-/blob/1a12337058f260d38405886d82da5e8bb5d8da0b/app/models/namespace.rb#L786).

To perform multi-key commands, developers may use the [`.pipelined`](https://github.com/redis-rb/redis-cluster-client#interfaces) method which splits and sends commands to each node and aggregates replies.
However, this does not work for [transactions](https://redis.io/docs/latest/develop/interact/transactions/) as Redis Cluster does not support cross-slot transactions.

For `Rails.cache`, we handle the `MGET` command found in `read_multi_get` by [patching it](https://gitlab.com/gitlab-org/gitlab/-/blob/c2bad2aac25e2f2778897bd4759506a72b118b15/lib/gitlab/patch/redis_cache_store.rb#L10) to use the `.pipelined` method.
The minimum size of the pipeline is set to 1000 commands and it can be adjusted by using the `GITLAB_REDIS_CLUSTER_PIPELINE_BATCH_LIMIT` environment variable.

## Redis in structured logging

For GitLab Team Members: There are <i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
[basic](https://www.youtube.com/watch?v=Uhdj19Dc6vU) and
<i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [advanced](https://youtu.be/jw1Wv2IJxzs)
videos that show how you can work with the Redis
structured logging fields on GitLab.com.

Our [structured logging](logging.md#use-structured-json-logging) for web
requests and Sidekiq jobs contains fields for the duration, call count,
bytes written, and bytes read per Redis instance, along with a total for
all Redis instances. For a particular request, this might look like:

| Field | Value |
| --- | --- |
| `json.queue_duration_s` | 0.01 |
| `json.redis_cache_calls` | 1 |
| `json.redis_cache_duration_s` | 0 |
| `json.redis_cache_read_bytes` | 109 |
| `json.redis_cache_write_bytes` | 49 |
| `json.redis_calls` | 2 |
| `json.redis_duration_s` | 0.001 |
| `json.redis_read_bytes` | 111 |
| `json.redis_shared_state_calls` | 1 |
| `json.redis_shared_state_duration_s` | 0 |
| `json.redis_shared_state_read_bytes` | 2 |
| `json.redis_shared_state_write_bytes` | 206 |
| `json.redis_write_bytes` | 255 |

As all of these fields are indexed, it is then straightforward to
investigate Redis usage in production. For instance, to find the
requests that read the most data from the cache, we can just sort by
`redis_cache_read_bytes` in descending order.

### The slow log

NOTE:
There is a [video showing how to see the slow log](https://youtu.be/BBI68QuYRH8) (GitLab internal)
on GitLab.com

<!-- vale gitlab_base.Substitutions = NO -->

On GitLab.com, entries from the [Redis slow log](https://redis.io/docs/latest/commands/slowlog/) are available in the
`pubsub-redis-inf-gprd*` index with the [`redis.slowlog` tag](https://log.gprd.gitlab.net/app/kibana#/discover?_g=(filters:!(),refreshInterval:(pause:!t,value:0),time:(from:now-1d,to:now))&_a=(columns:!(json.type,json.command,json.exec_time_s),filters:!(('$state':(store:appState),meta:(alias:!n,disabled:!f,index:AWSQX_Vf93rHTYrsexmk,key:json.tag,negate:!f,params:(query:redis.slowlog),type:phrase),query:(match:(json.tag:(query:redis.slowlog,type:phrase))))),index:AWSQX_Vf93rHTYrsexmk)).
This shows commands that have taken a long time and may be a performance
concern.

<!-- vale gitlab_base.Substitutions = YES -->

The
[`fluent-plugin-redis-slowlog`](https://gitlab.com/gitlab-org/ruby/gems/fluent-plugin-redis-slowlog)
project is responsible for taking the `slowlog` entries from Redis and
passing to Fluentd (and ultimately Elasticsearch).

## Analyzing the entire keyspace

The [Redis Keyspace Analyzer](https://gitlab.com/gitlab-com/gl-infra/redis-keyspace-analyzer)
project contains tools for dumping the full key list and memory usage of a Redis
instance, and then analyzing those lists while eliminating potentially sensitive
data from the results. It can be used to find the most frequent key patterns, or
those that use the most memory.

Currently this is not run automatically for the GitLab.com Redis instances, but
is run manually on an as-needed basis.

## N+1 calls problem

> - Introduced in [`spec/support/helpers/redis_commands/recorder.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/spec/support/helpers/redis_commands/recorder.rb) via [`f696f670`](https://gitlab.com/gitlab-org/gitlab/-/commit/f696f670005435472354a3dc0c01aa271aef9e32)

`RedisCommands::Recorder` is a tool for detecting Redis N+1 calls problem from tests.

Redis is often used for caching purposes. Usually, cache calls are lightweight and
cannot generate enough load to affect the Redis instance. However, it is still
possible to trigger expensive cache recalculations without knowing that. Use this
tool to analyze Redis calls, and define expected limits for them.

### Create a test

It is implemented as a [`ActiveSupport::Notifications`](https://api.rubyonrails.org/classes/ActiveSupport/Notifications.html) instrumenter.

You can create a test that verifies that a testable code only makes
a single Redis call:

```ruby
it 'avoids N+1 Redis calls' do
  control = RedisCommands::Recorder.new { visit_page }

  expect(control.count).to eq(1)
end
```

or a test that verifies the number of specific Redis calls:

```ruby
it 'avoids N+1 sadd Redis calls' do
  control = RedisCommands::Recorder.new { visit_page }

  expect(control.by_command(:sadd).count).to eq(1)
end
```

You can also provide a pattern to capture only specific Redis calls:

```ruby
it 'avoids N+1 Redis calls to forks_count key' do
  control = RedisCommands::Recorder.new(pattern: 'forks_count') { visit_page }

  expect(control.count).to eq(1)
end
```

You also can use special matchers `exceed_redis_calls_limit` and
`exceed_redis_command_calls_limit` to define an upper limit for
a number of Redis calls:

```ruby
it 'avoids N+1 Redis calls' do
  control = RedisCommands::Recorder.new { visit_page }

  expect(control).not_to exceed_redis_calls_limit(1)
end
```

```ruby
it 'avoids N+1 sadd Redis calls' do
  control = RedisCommands::Recorder.new { visit_page }

  expect(control).not_to exceed_redis_command_calls_limit(:sadd, 1)
end
```

These tests can help to identify N+1 problems related to Redis calls,
and make sure that the fix for them works as expected.

### See also

- [Database query recorder](database/query_recorder.md)

## Utility classes

We have some extra classes to help with specific use cases. These are
mostly for fine-grained control of Redis usage, so they wouldn't be used
in combination with the `Rails.cache` wrapper: we'd either use
`Rails.cache` or these classes and literal Redis commands.

We prefer using `Rails.cache` so we can reap the benefits of future
optimizations done to Rails. Ruby objects are
[marshalled](https://github.com/rails/rails/blob/v6.0.3.1/activesupport/lib/active_support/cache/redis_cache_store.rb#L447)
when written to Redis, so we must pay attention to store neither huge objects,
nor untrusted user input.

Typically we would only use these classes when at least one of the
following is true:

1. We want to manipulate data on a non-cache Redis instance.
1. `Rails.cache` does not support the operations we want to perform.

### `Gitlab::Redis::{Cache,SharedState,Queues}`

These classes wrap the Redis instances (using
[`Gitlab::Redis::Wrapper`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/redis/wrapper.rb))
to make it convenient to work with them directly. The typical use is to
call `.with` on the class, which takes a block that yields the Redis
connection. For example:

```ruby
# Get the value of `key` from the shared state (persistent) Redis
Gitlab::Redis::SharedState.with { |redis| redis.get(key) }

# Check if `value` is a member of the set `key`
Gitlab::Redis::Cache.with { |redis| redis.sismember(key, value) }
```

### `Gitlab::Redis::Boolean`

In Redis, every value is a string.
[`Gitlab::Redis::Boolean`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/redis/boolean.rb)
makes sure that booleans are encoded and decoded consistently.

### `Gitlab::Redis::HLL`

The Redis [`PFCOUNT`](https://redis.io/docs/latest/commands/pfcount/),
[`PFADD`](https://redis.io/docs/latest/commands/pfadd/), and
[`PFMERGE`](https://redis.io/docs/latest/commands/pfmerge/) commands operate on
HyperLogLogs, a data structure that allows estimating the number of unique
elements with low memory usage. For more information,
see [HyperLogLogs in Redis](https://thoughtbot.com/blog/hyperloglogs-in-redis).

[`Gitlab::Redis::HLL`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/redis/hll.rb)
provides a convenient interface for adding and counting values in HyperLogLogs.

### `Gitlab::SetCache`

For cases where we need to efficiently check the whether an item is in a group
of items, we can use a Redis set.
[`Gitlab::SetCache`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/set_cache.rb)
provides an `#include?` method that uses the
[`SISMEMBER`](https://redis.io/docs/latest/commands/sismember/) command, as well as `#read`
to fetch all entries in the set.

This is used by the
[`RepositorySetCache`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/repository_set_cache.rb)
to provide a convenient way to use sets to cache repository data like branch
names.

## Background migration

Redis-based migrations involve using the `SCAN` command to scan the entire Redis instance for certain key patterns.
For large Redis instances, the migration might [exceed the time limit](migration_style_guide.md#how-long-a-migration-should-take)
for regular or post-deployment migrations. [`RedisMigrationWorker`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/workers/redis_migration_worker.rb)
performs long-running Redis migrations as a background migration.

To perform a background migration by creating a class:

```ruby
module Gitlab
  module BackgroundMigration
    module Redis
      class BackfillCertainKey
        def perform(keys)
        # implement logic to clean up or backfill keys
        end

        def scan_match_pattern
        # define the match pattern for the `SCAN` command
        end

        def redis
        # define the exact Redis instance
        end
      end
    end
  end
end
```

To trigger the worker through a post-deployment migration:

```ruby
class ExampleBackfill < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  MIGRATION='BackfillCertainKey'

  def up
    queue_redis_migration_job(MIGRATION)
  end
end
```
