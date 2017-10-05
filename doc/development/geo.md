# GitLab Geo

Geo feature requires that we orchestrate a lot of components together.
For the Database we need to setup replication, writing operations that stores
data directly to disk replicates asynchronously by sending Webhook requests
from **Primary** to **Secondary** nodes, and _assets_ are to be replicated in
a future release using either a shared filesystem architecture or an object
store setup with geographical replication.


## Primary and Secondary

There can be only one **Primary** node, which is the one that can do writing
operations. Both share the same codebase and are distinguished by a feature
toggle mechanism (see `Gitlab::Geo`).

We use the values from `gitlab.yml`: `host`, `port`, `relative_url_root`
and search in the database to identity which node we are in
(see `Gitlab::Geo.current_node`).

Most of the Geo important methods are cached by the `RequestStore`, to reduce
the performance impact of using the methods throghout the codebase.

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

`.primary?` and `.secondary?` are not mutually excludable, so you should never
take for granted that when one of them returns `false`, other will be true.

Both methods check if Geo is `.enabled?`, so there is a "third" state where
both will return false (when Geo is not enabled).


## Enablement

We consider Geo feature enabled when the user has a valid license with the
feature included, and they have at least one node defined at the Geo Nodes
screen.


## Communication

### Custom code (GitLab 8.6 and earlier)

In GitLab versions before 8.6 custom code is used to handle
notification from **Primary** to **Secondary** by HTTP requests.

### System hooks (GitLab 8.7 till 9.5)

Later was decided to move away from custom code and integrate by using
**System Webhooks**. More people are using them, so many would benefit from
improvements made to this communication layer.

There is a specific **internal** endpoint in our api code (Grape),
that receives all requests from this System Hooks:
`/api/v3/geo/receive_events`.

We switch and filter from each event by the `event_name` field.

### Geo Log Cursor (GitLab 10.0 and up)

Since GitLab 10.0, **System Webhooks** are no longer used, and Geo Log
Cursor is used instead. The Log Cursor traverses the `Geo::EventLog`
to see if there are changes since the last time the log was checked
and will handle repository updates, deletes, changes & renames.


## Readonly

All **Secondary** nodes are read-only.

We have a Rails Middleware that filters any potentially writing operations
and prevent user from trying to update the database and getting a 500 error
(see `Gitlab::Middleware::ReadonlyGeo`).

Database will already be read-only in a replicated setup, so we don't need to
take any extra step for that.

We do use our feature toggle `.secondary?` to coordinate Git operations and do
the correct authorization (denying writing on any secondary node).

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
[XSendfile](https://www.nginx.com/resources/wiki/start/topics/examples/xsendfile/)
feature, which allows nginx to handle the file transfer without tying up Rails
or Workhorse.

## Geo Tracking Database

Secondary Geo nodes track data about what has been downloaded in a second
PostgreSQL database that is distinct from the production GitLab database.
The database configuration is set in `config/database_geo.yml`.
`db/geo` contains the schema and migrations for this database.

To write a migration for the database, use the `GeoMigrationGenerator`:

```
rails g geo_generation [args] [options]
```

To migrate the tracking database, run:

```
bundle exec rake geo:db:migrate
```
