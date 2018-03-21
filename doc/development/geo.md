# Geo (development)

Geo feature requires that we orchestrate a lot of components together.
For the Database we need to setup a streaming replication. Any operation on disk
is logged in an events table, that will leverage the database replication itself
from **Primary** to **Secondary** nodes. These events are processed by the
**Geo Log Cursor** daemon (on the Secondary) and asynchronous jobs takes care of
the changes.

To keep track on the state of the replication, **Secondary** nodes includes an
additional PostgreSQL database, that includes metadata from all the tracked
repositories and assets. This additional database is required because we can't
do any writing operation on the replicated database.


## Primary and Secondary

There can be only one **Primary** node, which is the one that can do writing
operations. Both share the same codebase and are distinguished by a feature
toggle mechanism (see `Gitlab::Geo`).

We use the values from `gitlab.yml`: `host`, `port`, `relative_url_root`
and search in the database to identify which node we are in
(see `Gitlab::Geo.current_node`).

Most of the Geo important methods are cached by the `RequestStore`, to reduce
the performance impact of using the methods throughout the codebase.

To execute a piece of code in a **Primary** node use:

```ruby
if Gitlab::Geo.primary?
  # code goes here
end
```

You can do the same thing for a **Secondary** node:

```ruby
if Gitlab::Geo.secondary?
  # code goes here
end
```

`.primary?` and `.secondary?` are not mutually exclusive, so you should never
take for granted that when one of them returns `false`, other will be true.

Both methods check if Geo is `.enabled?`, so there is a "third" state where
both will return false (when Geo is not enabled).

There is also an additional gotcha when dealing with `initializers` or with
things that happen during initialization time. We use in a few places the
`Gitlab::Geo.geo_database_configured?` to check if node has the additional
database which only happens in the secondary node, so we can overcome some
racing conditions that could happen during bootstrapping of a new node.


## Enablement

We consider Geo feature enabled when the user has a valid license with the
feature included, and they have at least one node defined at the Geo Nodes
screen.

See `Gitlab::Geo.enabled?` and `Gitlab::Geo.license_allows?`.


## Communication

The communication channel has changed since first iteration, you can check here
historic decisions and why we moved to new implementations.

### Custom code (GitLab 8.6 and earlier)

In GitLab versions before 8.6 custom code is used to handle
notification from **Primary** to **Secondary** by HTTP requests.

### System hooks (GitLab 8.7 till 9.5)

Later was decided to move away from custom code and integrate by using
**System Webhooks**. More people are using them, so many would benefit from
improvements made to this communication layer.

There is a specific **internal** endpoint in our api code (Grape),
that receives all requests from this System Hooks:
`/api/{v3,v4}/geo/receive_events`.

We switch and filter from each event by the `event_name` field.


### Geo Log Cursor (GitLab 10.0 and up)

Since GitLab 10.0, **System Webhooks** are no longer used, and Geo Log
Cursor is used instead. The Log Cursor traverses the `Geo::EventLog`
to see if there are changes since the last time the log was checked
and will handle repository updates, deletes, changes & renames.

The table is within the replicated database. This has two advantages over the
old method:

1. Replication is synchronous and we preserve the order of events
2. Replication of the events happen at the same time as the changes in the
   database


## Read-only

All **Secondary** nodes are read-only.

The general principle of a [read-only database](verifying_database_capabilities.md#read-only-database)
applies to all Geo secondary nodes. So `Gitlab::Database.read_only?`
will always return `true` on a secondary node.

When some write actions are not allowed, because the node is a
secondary, consider the `Gitlab::Database.read_only?` or `Gitlab::Database.read_write?`
guard, instead of `Gitlab::Geo.secondary?`.

Database itself will already be read-only in a replicated setup, so we
don't need to take any extra step for that.


## File Transfers

Secondary Geo Nodes need to transfer files, such as LFS objects, attachments, avatars,
etc. from the primary. To do this, secondary nodes have a separate tracking database
that records which objects it needs to transfer.

Files are copied via HTTP(s) and initiated via the
`/api/v4/geo/transfers/:type/:id` endpoint.


### Authentication

To authenticate file transfers, each GeoNode has two fields:

1. A public access key (`access_key`)
2. A secret access key (`secret_access_key`)

The secondary authenticates itself via a [JWT request](https://jwt.io/). When the
secondary wishes to download a file, it sends an HTTP request with the `Authorization`
header:

```
Authorization: GL-Geo <access_key>:<JWT payload>
```

The primary uses the `access_key` to look up the corresponding Geo node and
decrypt the JWT payload, which contains additional information to identify the
file request. This ensures that the secondary downloads the right file for the
right database ID. For example, for an LFS object, the request must also
include the SHA256 of the file. An example JWT payload looks like:

```
{ "data": { sha256: "31806bb23580caab78040f8c45d329f5016b0115" }, iat: "1234567890" }
```

If the data checks out, then the Geo primary sends data via the
[X-Sendfile](https://www.nginx.com/resources/wiki/start/topics/examples/xsendfile/)
feature, which allows nginx to handle the file transfer without tying up Rails
or Workhorse.

Please note that JWT requires synchronized clocks between involved machines,
otherwise it may fail with an encryption error.


## Geo Tracking Database

Secondary Geo nodes track data about what has been downloaded in a second
PostgreSQL database that is distinct from the production GitLab database.
The database configuration is set in `config/database_geo.yml`.
`ee/db/geo` contains the schema and migrations for this database.

To write a migration for the database, use the `GeoMigrationGenerator`:

```
rails g geo_migration [args] [options]
```

To migrate the tracking database, run:

```
bundle exec rake geo:db:migrate
```

In 10.1 we are introducing PostgreSQL FDW to bridge this database with the
replicated one, so we can perform queries joining tables from both instances.

This is useful for the Geo Log Cursor and improves the performance of some
synchronization operations.

While FDW is available in older versions of Postgres, we needed to bump the
minimum required version to 9.6 as this includes many performance improvements
to the FDW implementation.

### Refeshing the Foreign Tables

Whenever the database schema changes on the primary, the secondary will need to refresh
its foreign tables by running the following:

```sh
bundle exec rake geo:db:refresh_foreign_tables
```

Failure to do this will prevent the secondary from functioning properly. The
secondary will generate error messages, as the following PostgreSQL error:

```
ERROR:  relation "gitlab_secondary.ci_job_artifacts" does not exist at character 323
STATEMENT:                SELECT a.attname, format_type(a.atttypid, a.atttypmod),
                          pg_get_expr(d.adbin, d.adrelid), a.attnotnull, a.atttypid, a.atttypmod
                     FROM pg_attribute a LEFT JOIN pg_attrdef d
                       ON a.attrelid = d.adrelid AND a.attnum = d.adnum
                    WHERE a.attrelid = '"gitlab_secondary"."ci_job_artifacts"'::regclass
                      AND a.attnum > 0 AND NOT a.attisdropped
                    ORDER BY a.attnum
```
