# Redis guidelines

GitLab uses [Redis](https://redis.io) for three distinct purposes:

- Caching via `Rails.cache`.
- As a job processing queue with [Sidekiq](sidekiq_style_guide.md).
- To manage the shared application state.

Every application process is configured to use the same Redis servers, so they
can be used for inter-process communication in cases where [PostgreSQL](sql.md)
is less appropriate. For example, transient state or data that is written much
more often than it is read.

If [Geo](geo.md) is enabled, each Geo node gets its own, independent Redis
database.

## Key naming

Redis is a flat namespace with no hierarchy, which means we must pay attention
to key names to avoid collisions. Typically we use colon-separated elements to
provide a semblance of structure at application level. An example might be
`projects:1:somekey`.

Although we split our Redis usage into three separate purposes, and those may
map to separate Redis servers in a [Highly Available](../administration/high_availability/redis.md)
configuration, the default Omnibus and GDK setups share a single Redis server.
This means that keys should **always** be globally unique across the three
purposes.

It is usually better to use immutable identifiers - project ID rather than
full path, for instance - in Redis key names. If full path is used, the key will
stop being consulted if the project is renamed. If the contents of the key are
invalidated by a name change, it is better to include a hook that will expire
the entry, instead of relying on the key changing.

We don't use [Redis Cluster](https://redis.io/topics/cluster-tutorial) at the
moment, but may wish to in the future: [#118820](https://gitlab.com/gitlab-org/gitlab/-/issues/118820).

This imposes an additional constraint on naming: where GitLab is performing
operations that require several keys to be held on the same Redis server - for
instance, diffing two sets held in Redis - the keys should ensure that by
enclosing the changeable parts in curly braces, such as, `project:{1}:set_a` and
`project:{1}:set_b`.
