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

Previous implementation (GitLab =< 8.6.x) used custom code to handle
notification from **Primary** to **Secondary** by HTTP requests.

We decided to move away from custom code and integrate by using
**System Webhooks**, as we have more people using them, so any
improvements we make to this communication layer, many other will
benefit from.

There is a specific **internal** endpoint in our api code (Grape),
that receives all requests from this System Hooks:
`/api/v3/geo/receive_events`.

We switch and filter from each event by the `event_name` field.


## Readonly

All **Secondary** nodes are read-only.

We have a Rails Middleware that filters any potentially writing operations
and prevent user from trying to update the database and getting a 500 error
(see `Gitlab::Middleware::ReadonlyGeo`).

Database will already be read-only in a replicated setup, so we don't need to
take any extra step for that.

We do use our feature toggle `.secondary?` to coordinate Git operations and do
the correct authorization (denying writing on any secondary node).
