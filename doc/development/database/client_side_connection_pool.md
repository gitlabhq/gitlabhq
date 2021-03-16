---
type: dev, reference
stage: none
group: Development
info: "See the Technical Writers assigned to Development Guidelines: https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments-to-development-guidelines"
---

# Client-side connection-pool

Ruby processes accessing the database through
ActiveRecord, automatically calculate the connection-pool size for the
process based on the concurrency.

Because of the way [Ruby on Rails manages database
connections](#connection-lifecycle), it is important that we have at
least as many connections as we have threads. While there is a 'pool'
setting in [`database.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/config/database.yml.postgresql), it is not very practical because you need to
maintain it in tandem with the number of application threads. For this
reason, we override the number of allowed connections in the database
connection-pool based on the configured number of application threads.

`Gitlab::Runtime.max_threads` is the number of user-facing
application threads the process has been configured with. We also have
auxiliary threads that use database connections. As it isn't
straightforward to keep an accurate count of the number of auxiliary threads as
the application evolves over time, we just add a fixed headroom to the
number of user-facing threads. It is OK if this number is too large
because connections are instantiated lazily.

## Troubleshooting connection-pool issues

The connection-pool usage can be seen per environment in the [connection-pool
saturation
dashboard](https://dashboards.gitlab.net/d/alerts-sat_rails_db_connection_pool/alerts-rails_db_connection_pool-saturation-detail?orgId=1).

If the connection-pool is too small, this would manifest in
`ActiveRecord::ConnectionTimeoutError`s from the application. Because we alert
when almost all connections are used, we should know this before
timeouts occur. If this happens we can remediate by setting the
`DB_POOL_HEADROOM` environment variable to something bigger than the
hardcoded value (10).

At this point, we need to investigate what is using more connections
than we anticipated. To do that, we can use the
`gitlab_ruby_threads_running_threads` metric. For example, [this
graph](https://thanos.gitlab.net/graph?g0.range_input=1h&g0.max_source_resolution=0s&g0.expr=sum%20by%20(thread_name)%20(%20gitlab_ruby_threads_running_threads%7Buses_db_connection%3D%22yes%22%7D%20)&g0.tab=0)
shows all running threads that connect to the database by their
name. Threads labeled `puma worker` or `sidekiq_worker_thread` are
the threads that define `Gitlab::Runtime.max_threads` so those are
accounted for. If there's more than 10 other threads running, we could
consider raising the default headroom.

## Connection lifecycle

For web requests, a connection is obtained from the pool at the first
time a database query is made. The connection is returned to the pool
after the request completes.

For background jobs, the behavior is very similar. The thread obtains
a connection for the first query, and returns it after the job is
finished.

This is managed by Rails internally.
