---
stage: enablement
group: Tenant Scale
description: 'Cells Stateless Router Proposal'
status: rejected
---

_This proposal was superseded by the [routing service proposal](../routing-service.md)_

<!-- vale gitlab.FutureTense = NO -->

This document is a work-in-progress and represents a very early state of the
Cells design. Significant aspects are not documented, though we expect to add
them in the future. This is one possible architecture for Cells, and we intend to
contrast this with alternatives before deciding which approach to implement.
This documentation will be kept even if we decide not to implement this so that
we can document the reasons for not choosing this approach.

# Proposal: Stateless Router using Routes Learning

We will decompose `gitlab_users`, `gitlab_routes` and `gitlab_admin` related
tables so that they can be shared between all cells and allow any cell to
authenticate a user and route requests to the correct cell. Cells may receive
requests for the resources they don't own, but they know how to redirect back
to the correct cell.

The router is stateless and does not read from the `routes` database which
means that all interactions with the database still happen from the Rails
monolith. This architecture also supports regions by allowing for low traffic
databases to be replicated across regions.

Users are not directly exposed to the concept of Cells but instead they see
different data dependent on their chosen Organization.
[Organizations](../goals.md#organizations) will be a new entity introduced to enforce isolation in the
application and allow us to decide which request routes to which Cell, since an
Organization can only be on a single Cell.

## Differences

The main difference between this proposal and one [with buffering requests](proposal-stateless-router-with-buffering-requests.md)
is that this proposal uses a pre-flight API request (`/api/v4/internal/cells/learn`) to redirect the request body to the correct Cell.
This means that each request is sent exactly once to be processed, but the URI is used to decode which Cell it should be directed.

## Summary in diagrams

This shows how a user request routes via DNS to the nearest router and the router chooses a cell to send the request to.

```mermaid
graph TD;
    user((User));
    dns[DNS];
    router_us(Router);
    router_eu(Router);
    cell_us0{Cell US0};
    cell_us1{Cell US1};
    cell_eu0{Cell EU0};
    cell_eu1{Cell EU1};
    user-->dns;
    dns-->router_us;
    dns-->router_eu;
    subgraph Europe
    router_eu-->cell_eu0;
    router_eu-->cell_eu1;
    end
    subgraph United States
    router_us-->cell_us0;
    router_us-->cell_us1;
    end
```

### More detail

This shows that the router can actually send requests to any cell. The user will
get the closest router to them geographically.

```mermaid
graph TD;
    user((User));
    dns[DNS];
    router_us(Router);
    router_eu(Router);
    cell_us0{Cell US0};
    cell_us1{Cell US1};
    cell_eu0{Cell EU0};
    cell_eu1{Cell EU1};
    user-->dns;
    dns-->router_us;
    dns-->router_eu;
    subgraph Europe
    router_eu-->cell_eu0;
    router_eu-->cell_eu1;
    end
    subgraph United States
    router_us-->cell_us0;
    router_us-->cell_us1;
    end
    router_eu-.->cell_us0;
    router_eu-.->cell_us1;
    router_us-.->cell_eu0;
    router_us-.->cell_eu1;
```

### Even more detail

This shows the databases. `gitlab_users` and `gitlab_routes` exist only in the
US region but are replicated to other regions. Replication does not have an
arrow because it's too hard to read the diagram.

```mermaid
graph TD;
    user((User));
    dns[DNS];
    router_us(Router);
    router_eu(Router);
    cell_us0{Cell US0};
    cell_us1{Cell US1};
    cell_eu0{Cell EU0};
    cell_eu1{Cell EU1};
    db_gitlab_users[(gitlab_users Primary)];
    db_gitlab_routes[(gitlab_routes Primary)];
    db_gitlab_users_replica[(gitlab_users Replica)];
    db_gitlab_routes_replica[(gitlab_routes Replica)];
    db_cell_us0[(gitlab_main/gitlab_ci Cell US0)];
    db_cell_us1[(gitlab_main/gitlab_ci Cell US1)];
    db_cell_eu0[(gitlab_main/gitlab_ci Cell EU0)];
    db_cell_eu1[(gitlab_main/gitlab_ci Cell EU1)];
    user-->dns;
    dns-->router_us;
    dns-->router_eu;
    subgraph Europe
    router_eu-->cell_eu0;
    router_eu-->cell_eu1;
    cell_eu0-->db_cell_eu0;
    cell_eu0-->db_gitlab_users_replica;
    cell_eu0-->db_gitlab_routes_replica;
    cell_eu1-->db_gitlab_users_replica;
    cell_eu1-->db_gitlab_routes_replica;
    cell_eu1-->db_cell_eu1;
    end
    subgraph United States
    router_us-->cell_us0;
    router_us-->cell_us1;
    cell_us0-->db_cell_us0;
    cell_us0-->db_gitlab_users;
    cell_us0-->db_gitlab_routes;
    cell_us1-->db_gitlab_users;
    cell_us1-->db_gitlab_routes;
    cell_us1-->db_cell_us1;
    end
    router_eu-.->cell_us0;
    router_eu-.->cell_us1;
    router_us-.->cell_eu0;
    router_us-.->cell_eu1;
```

## Summary of changes

1. Tables related to User data (including profile settings, authentication credentials, personal access tokens) are decomposed into a `gitlab_users` schema
1. The `routes` table is decomposed into `gitlab_routes` schema
1. The `application_settings` (and probably a few other instance level tables) are decomposed into `gitlab_admin` schema
1. A new column `routes.cell_id` is added to `routes` table
1. A new Router service exists to choose which cell to route a request to.
1. If a router receives a new request it will send `/api/v4/internal/cells/learn?method=GET&path_info=/group-org/project` to learn which Cell can process it
1. A new concept will be introduced in GitLab called an organization
1. We require all existing endpoints to be routable by URI, or be fixed to a specific Cell for processing. This requires changing ambiguous endpoints like `/dashboard` to be scoped like `/organizations/my-organization/-/dashboard`
1. Endpoints like `/admin` would be routed always to the specific Cell, like `cell_0`
1. Each Cell can respond to `/api/v4/internal/cells/learn` and classify each endpoint
1. Writes to `gitlab_users` and `gitlab_routes` are sent to a primary PostgreSQL server in our `US` region but reads can come from replicas in the same region. This will add latency for these writes but we expect they are infrequent relative to the rest of GitLab.

## Pre-flight request learning

While processing a request the URI will be decoded and a pre-flight request
will be sent for each non-cached endpoint.

When asking for the endpoint GitLab Rails will return information about
the routable path. GitLab Rails will decode `path_info` and match it to
an existing endpoint and find a routable entity (like project). The router will
treat this as short-lived cache information.

1. Prefix match: `/api/v4/internal/cells/learn?method=GET&path_info=/gitlab-org/gitlab-test/-/issues`

   ```json
   {
      "path": "/gitlab-org/gitlab-test",
      "cell": "cell_0",
      "source": "routable"
   }
   ```

1. Some endpoints might require an exact match: `/api/v4/internal/cells/learn?method=GET&path_info=/-/profile`

   ```json
   {
      "path": "/-/profile",
      "cell": "cell_0",
      "source": "fixed",
      "exact": true
   }
   ```

## Detailed explanation of default organization in the first iteration

All users will get a new column `users.default_organization` which they can
control in user settings. We will introduce a concept of the
`GitLab.com Public` organization. This will be set as the default organization for all existing
users. This organization will allow the user to see data from all namespaces in
`Cell US0` (ie. our original GitLab.com instance). This behavior can be invisible to
existing users such that they don't even get told when they are viewing a
global page like `/dashboard` that it's even scoped to an organization.

Any new users with a default organization other than `GitLab.com Public` will have
a distinct user experience and will be fully aware that every page they load is
only ever scoped to a single organization. These users can never
load any global pages like `/dashboard` and will end up being redirected to
`/organizations/<DEFAULT_ORGANIZATION>/-/dashboard`. This may also be the case
for legacy APIs and such users may only ever be able to use APIs scoped to a
organization.

## Detailed explanation of Admin Area settings

We believe that maintaining and synchronizing Admin Area settings will be
frustrating and painful so to avoid this we will decompose and share all Admin Area
settings in the `gitlab_admin` schema. This should be safe (similar to other
shared schemas) because these receive very little write traffic.

In cases where different cells need different settings (eg. the
Elasticsearch URL), we will either decide to use a templated
format in the relevant `application_settings` row which allows it to be dynamic
per cell. Alternatively if that proves difficult we'll introduce a new table
called `per_cell_application_settings` and this will have 1 row per cell to allow
setting different settings per cell. It will still be part of the `gitlab_admin`
schema and shared which will allow us to centrally manage it and simplify
keeping settings in sync for all cells.

## Pros

1. Router is stateless and can live in many regions. We use Anycast DNS to resolve to nearest region for the user.
1. Cells can receive requests for namespaces in the wrong cell and the user
   still gets the right response as well as caching at the router that
   ensures the next request is sent to the correct cell so the next request
   will go to the correct cell
1. The majority of the code still lives in `gitlab` rails codebase. The Router doesn't actually need to understand how GitLab URLs are composed.
1. Since the responsibility to read and write `gitlab_users`,
   `gitlab_routes` and `gitlab_admin` still lives in Rails it means minimal
   changes will be needed to the Rails application compared to extracting
   services that need to isolate the domain models and build new interfaces.
1. Compared to a separate routing service this allows the Rails application
   to encode more complex rules around how to map URLs to the correct cell
   and may work for some existing API endpoints.
1. All the new infrastructure (just a router) is optional and a single-cell
   self-managed installation does not even need to run the Router and there are
   no other new services.

## Cons

1. `gitlab_users`, `gitlab_routes` and `gitlab_admin` databases may need to be
   replicated across regions and writes need to go across regions. We need to
   do an analysis on write TPS for the relevant tables to determine if this is
   feasible.
1. Sharing access to the database from many different Cells means that they are
   all coupled at the Postgres schema level and this means changes to the
   database schema need to be done carefully in sync with the deployment of all
   Cells. This limits us to ensure that Cells are kept in closely similar
   versions compared to an architecture with shared services that have an API
   we control.
1. Although most data is stored in the right region there can be requests
   proxied from another region which may be an issue for certain types
   of compliance.
1. Data in `gitlab_users` and `gitlab_routes` databases must be replicated in
   all regions which may be an issue for certain types of compliance.
1. The router cache may need to be very large if we get a wide variety of URLs
   (ie. long tail). In such a case we may need to implement a 2nd level of
   caching in user cookies so their frequently accessed pages always go to the
   right cell the first time.
1. Having shared database access for `gitlab_users` and `gitlab_routes`
   from multiple cells is an unusual architecture decision compared to
   extracting services that are called from multiple cells.
1. It is very likely we won't be able to find cacheable elements of a
   GraphQL URL and often existing GraphQL endpoints are heavily dependent on
   ids that won't be in the `routes` table so cells won't necessarily know
   what cell has the data. As such we'll probably have to update our GraphQL
   calls to include an organization context in the path like
   `/api/organizations/<organization>/graphql`.
1. This architecture implies that implemented endpoints can only access data
   that are readily accessible on a given Cell, but are unlikely
   to aggregate information from many Cells.
1. All unknown routes are sent to the latest deployment which we assume to be `Cell US0`.
   This is required as newly added endpoints will be only decodable by latest cell.
   Likely this is not a problem for the `/internal/cells/learn` is it is lightweight
   to process and this should not cause a performance impact.

## Example database configuration

Handling shared `gitlab_users`, `gitlab_routes` and `gitlab_admin` databases, while having dedicated `gitlab_main` and `gitlab_ci` databases should already be handled by the way we use `config/database.yml`. We should also, already be able to handle the dedicated EU replicas while having a single US primary for `gitlab_users` and `gitlab_routes`. Below is a snippet of part of the database configuration for the Cell architecture described above.

**Cell US0**:

```yaml
# config/database.yml
production:
  main:
    host: postgres-main.cell-us0.primary.consul
    load_balancing:
      discovery: postgres-main.cell-us0.replicas.consul
  ci:
    host: postgres-ci.cell-us0.primary.consul
    load_balancing:
      discovery: postgres-ci.cell-us0.replicas.consul
  users:
    host: postgres-users-primary.consul
    load_balancing:
      discovery: postgres-users-replicas.us.consul
  routes:
    host: postgres-routes-primary.consul
    load_balancing:
      discovery: postgres-routes-replicas.us.consul
  admin:
    host: postgres-admin-primary.consul
    load_balancing:
      discovery: postgres-admin-replicas.us.consul
```

**Cell EU0**:

```yaml
# config/database.yml
production:
  main:
    host: postgres-main.cell-eu0.primary.consul
    load_balancing:
      discovery: postgres-main.cell-eu0.replicas.consul
  ci:
    host: postgres-ci.cell-eu0.primary.consul
    load_balancing:
      discovery: postgres-ci.cell-eu0.replicas.consul
  users:
    host: postgres-users-primary.consul
    load_balancing:
      discovery: postgres-users-replicas.eu.consul
  routes:
    host: postgres-routes-primary.consul
    load_balancing:
      discovery: postgres-routes-replicas.eu.consul
  admin:
    host: postgres-admin-primary.consul
    load_balancing:
      discovery: postgres-admin-replicas.eu.consul
```

## Request flows

1. `gitlab-org` is a top level namespace and lives in `Cell US0` in the `GitLab.com Public` organization
1. `my-company` is a top level namespace and lives in `Cell EU0` in the `my-organization` organization

### Experience for paying user that is part of `my-organization`

Such a user will have a default organization set to `/my-organization` and will be
unable to load any global routes outside of this organization. They may load other
projects/namespaces but their MR/Todo/Issue counts at the top of the page will
not be correctly populated in the first iteration. The user will be aware of
this limitation.

#### Goes to `/my-company/my-project` while logged in

1. User is in Europe so DNS resolves to the router in Europe
1. They request `/my-company/my-project` without the router cache, so the router chooses randomly `Cell EU1`
1. The `/internal/cells/learn` is sent to `Cell EU1`, which responds that resource lives on `Cell EU0`
1. `Cell EU0` returns the correct response
1. The router now caches and remembers any request paths matching `/my-company/*` should go to `Cell EU0`

```mermaid
sequenceDiagram
    participant user as User
    participant router_eu as Router EU
    participant cell_eu0 as Cell EU0
    participant cell_eu1 as Cell EU1
    user->>router_eu: GET /my-company/my-project
    router_eu->>cell_eu1: /api/v4/internal/cells/learn?method=GET&path_info=/my-company/my-project
    cell_eu1->>router_eu: {path: "/my-company", cell: "cell_eu0", source: "routable"}
    router_eu->>cell_eu0: GET /my-company/my-project
    cell_eu0->>user: <h1>My Project...
```

#### Goes to `/my-company/my-project` while not logged in

1. User is in Europe so DNS resolves to the router in Europe
1. The router does not have `/my-company/*` cached yet so it chooses randomly `Cell EU1`
1. The `/internal/cells/learn` is sent to `Cell EU1`, which responds that resource lives on `Cell EU0`
1. `Cell EU0` redirects them through a login flow
1. User requests `/users/sign_in`, uses random Cell to run `/internal/cells/learn`
1. The `Cell EU1` responds with `cell_0` as a fixed route
1. User after login requests `/my-company/my-project` which is cached and stored in `Cell EU0`
1. `Cell EU0` returns the correct response

```mermaid
sequenceDiagram
    participant user as User
    participant router_eu as Router EU
    participant cell_eu0 as Cell EU0
    participant cell_eu1 as Cell EU1
    user->>router_eu: GET /my-company/my-project
    router_eu->>cell_eu1: /api/v4/internal/cells/learn?method=GET&path_info=/my-company/my-project
    cell_eu1->>router_eu: {path: "/my-company", cell: "cell_eu0", source: "routable"}
    router_eu->>cell_eu0: GET /my-company/my-project
    cell_eu0->>user: 302 /users/sign_in?redirect=/my-company/my-project
    user->>router_eu: GET /users/sign_in?redirect=/my-company/my-project
    router_eu->>cell_eu1: /api/v4/internal/cells/learn?method=GET&path_info=/users/sign_in
    cell_eu1->>router_eu: {path: "/users", cell: "cell_eu0", source: "fixed"}
    router_eu->>cell_eu0: GET /users/sign_in?redirect=/my-company/my-project
    cell_eu0-->>user: <h1>Sign in...
    user->>router_eu: POST /users/sign_in?redirect=/my-company/my-project
    router_eu->>cell_eu0: POST /users/sign_in?redirect=/my-company/my-project
    cell_eu0->>user: 302 /my-company/my-project
    user->>router_eu: GET /my-company/my-project
    router_eu->>cell_eu0: GET /my-company/my-project
    router_eu->>cell_eu0: GET /my-company/my-project
    cell_eu0->>user: <h1>My Project...
```

#### Goes to `/my-company/my-other-project` after last step

1. User is in Europe so DNS resolves to the router in Europe
1. The router cache now has `/my-company/* => Cell EU0`, so the router chooses `Cell EU0`
1. `Cell EU0` returns the correct response as well as the cache header again

```mermaid
sequenceDiagram
    participant user as User
    participant router_eu as Router EU
    participant cell_eu0 as Cell EU0
    participant cell_eu1 as Cell EU1
    user->>router_eu: GET /my-company/my-project
    router_eu->>cell_eu0: GET /my-company/my-project
    cell_eu0->>user: <h1>My Project...
```

#### Goes to `/gitlab-org/gitlab` after last step

1. User is in Europe so DNS resolves to the router in Europe
1. The router has no cached value for this URL so randomly chooses `Cell EU0`
1. `Cell EU0` redirects the router to `Cell US0`
1. `Cell US0` returns the correct response as well as the cache header again

```mermaid
sequenceDiagram
    participant user as User
    participant router_eu as Router EU
    participant cell_eu0 as Cell EU0
    participant cell_us0 as Cell US0
    user->>router_eu: GET /gitlab-org/gitlab
    router_eu->>cell_eu0: /api/v4/internal/cells/learn?method=GET&path_info=/gitlab-org/gitlab
    cell_eu0->>router_eu: {path: "/gitlab-org", cell: "cell_us0", source: "routable"}
    router_eu->>cell_us0: GET /gitlab-org/gitlab
    cell_us0->>user: <h1>GitLab.org...
```

In this case the user is not on their "default organization" so their TODO
counter will not include their typical todos. We may choose to highlight this in
the UI somewhere. A future iteration may be able to fetch that for them from
their default organization.

#### Goes to `/`

1. User is in Europe so DNS resolves to the router in Europe
1. Router does not have a cache for `/` route (specifically rails never tells it to cache this route)
1. The Router choose `Cell EU0` randomly
1. The Rails application knows the users default organization is `/my-organization`, so
   it redirects the user to `/organizations/my-organization/-/dashboard`
1. The Router has a cached value for `/organizations/my-organization/*` so it then sends the
   request to `POD EU0`
1. `Cell EU0` serves up a new page `/organizations/my-organization/-/dashboard` which is the same
   dashboard view we have today but scoped to an organization clearly in the UI
1. The user is (optionally) presented with a message saying that data on this page is only
   from their default organization and that they can change their default
   organization if it's not right.

```mermaid
sequenceDiagram
    participant user as User
    participant router_eu as Router EU
    participant cell_eu0 as Cell EU0
    user->>router_eu: GET /
    router_eu->>cell_eu0: GET /
    cell_eu0->>user: 302 /organizations/my-organization/-/dashboard
    user->>router: GET /organizations/my-organization/-/dashboard
    router->>cell_eu0: GET /organizations/my-organization/-/dashboard
    cell_eu0->>user: <h1>My Company Dashboard... X-Gitlab-Cell-Cache={path_prefix:/organizations/my-organization/}
```

#### Goes to `/dashboard`

As above, they will end up on `/organizations/my-organization/-/dashboard` as
the rails application will already redirect `/` to the dashboard page.

### Goes to `/not-my-company/not-my-project` while logged in (but they don't have access since this project/group is private)

1. User is in Europe so DNS resolves to the router in Europe
1. The router knows that `/not-my-company` lives in `Cell US1` so sends the request to this
1. The user does not have access so `Cell US1` returns 404

```mermaid
sequenceDiagram
    participant user as User
    participant router_eu as Router EU
    participant cell_us1 as Cell US1
    user->>router_eu: GET /not-my-company/not-my-project
    router_eu->>cell_us1: GET /not-my-company/not-my-project
    cell_us1->>user: 404
```

#### Creates a new top level namespace

The user will be asked which organization they want the namespace to belong to.
If they select `my-organization` then it will end up on the same cell as all
other namespaces in `my-organization`. If they select nothing we default to
`GitLab.com Public` and it is clear to the user that this is isolated from
their existing organization such that they won't be able to see data from both
on a single page.

### Experience for GitLab team member that is part of `/gitlab-org`

Such a user is considered a legacy user and has their default organization set to
`GitLab.com Public`. This is a "meta" organization that does not really exist but
the Rails application knows to interpret this organization to mean that they are
allowed to use legacy global functionality like `/dashboard` to see data across
namespaces located on `Cell US0`. The rails backend also knows that the default cell to render any ambiguous
routes like `/dashboard` is `Cell US0`. Lastly the user will be allowed to
go to organizations on another cell like `/my-organization` but when they do the
user will see a message indicating that some data may be missing (eg. the
MRs/Issues/Todos) counts.

#### Goes to `/gitlab-org/gitlab` while not logged in

1. User is in the US so DNS resolves to the US router
1. The router knows that `/gitlab-org` lives in `Cell US0` so sends the request
   to this cell
1. `Cell US0` serves up the response

```mermaid
sequenceDiagram
    participant user as User
    participant router_us as Router US
    participant cell_us0 as Cell US0
    user->>router_us: GET /gitlab-org/gitlab
    router_us->>cell_us0: GET /gitlab-org/gitlab
    cell_us0->>user: <h1>GitLab.org...
```

#### Goes to `/`

1. User is in US so DNS resolves to the router in US
1. Router does not have a cache for `/` route (specifically rails never tells it to cache this route)
1. The Router chooses `Cell US1` randomly
1. The Rails application knows the users default organization is `GitLab.com Public`, so
   it redirects the user to `/dashboards` (only legacy users can see
   `/dashboard` global view)
1. Router does not have a cache for `/dashboard` route (specifically rails never tells it to cache this route)
1. The Router chooses `Cell US1` randomly
1. The Rails application knows the users default organization is `GitLab.com Public`, so
   it allows the user to load `/dashboards` (only legacy users can see
   `/dashboard` global view) and redirects to router the legacy cell which is `Cell US0`
1. `Cell US0` serves up the global view dashboard page `/dashboard` which is the same
   dashboard view we have today

```mermaid
sequenceDiagram
    participant user as User
    participant router_us as Router US
    participant cell_us0 as Cell US0
    participant cell_us1 as Cell US1
    user->>router_us: GET /
    router_us->>cell_us1: GET /
    cell_us1->>user: 302 /dashboard
    user->>router_us: GET /dashboard
    router_us->>cell_us1: /api/v4/internal/cells/learn?method=GET&path_info=/dashboard
    cell_us1->>router_us: {path: "/dashboard", cell: "cell_us0", source: "routable"}
    router_us->>cell_us0: GET /dashboard
    cell_us0->>user: <h1>Dashboard...
```

#### Goes to `/my-company/my-other-project` while logged in (but they don't have access since this project is private)

They get a 404.

### Experience for non-authenticated users

Flow is similar to logged in users except global routes like `/dashboard` will
redirect to the login page as there is no default organization to choose from.

### A new customers signs up

They will be asked if they are already part of an organization or if they'd
like to create one. If they choose neither they end up no the default
`GitLab.com Public` organization.

### An organization is moved from 1 cell to another

TODO

### GraphQL/API requests which don't include the namespace in the URL

TODO

### The autocomplete suggestion functionality in the search bar which remembers recent issues/MRs

TODO

### Global search

TODO

## Administrator

### Loads `/admin` page

1. The `/admin` is locked to `Cell US0`
1. Some endpoints of `/admin`, like Projects in Admin are scoped to a Cell
   and users needs to choose the correct one in a dropdown, which results in endpoint
   like `/admin/cells/cell_0/projects`.

Admin Area settings in Postgres are all shared across all cells to avoid
divergence but we still make it clear in the URL and UI which cell is serving
the Admin Area page as there is dynamic data being generated from these pages and
the operator may want to view a specific cell.

## More Technical Problems To Solve

### Replicating User Sessions Between All Cells

Today user sessions live in Redis but each cell will have their own Redis instance. We already use a dedicated Redis instance for sessions so we could consider sharing this with all cells like we do with `gitlab_users` PostgreSQL database. But an important consideration will be latency as we would still want to mostly fetch sessions from the same region.

An alternative might be that user sessions get moved to a JWT payload that encodes all the session data but this has downsides. For example, it is difficult to expire a user session, when their password changes or for other reasons, if the session lives in a JWT controlled by the user.

### How do we migrate between Cells

Migrating data between cells will need to factor all data stores:

1. PostgreSQL
1. Redis Shared State
1. Gitaly
1. Elasticsearch

### Is it still possible to leak the existence of private groups via a timing attack?

If you have router in EU, and you know that EU router by default redirects
to EU located Cells, you know their latency (lets assume 10 ms). Now, if your
request is bounced back and redirected to US which has different latency
(lets assume that roundtrip will be around 60 ms) you can deduce that 404 was
returned by US Cell and know that your 404 is in fact 403.

We may defer this until we actually implement a cell in a different region. Such timing attacks are already theoretically possible with the way we do permission checks today but the timing difference is probably too small to be able to detect.

One technique to mitigate this risk might be to have the router add a random
delay to any request that returns 404 from a cell.

## Should runners be shared across all cells?

We have 2 options and we should decide which is easier:

1. Decompose runner registration and queuing tables and share them across all
   cells. This may have implications for scalability, and we'd need to consider
   if this would include group/project runners as this may have scalability
   concerns as these are high traffic tables that would need to be shared.
1. Runners are registered per-cell and, we probably have a separate fleet of
   runners for every cell or just register the same runners to many cells which
   may have implications for queueing

## How do we guarantee unique ids across all cells for things that cannot conflict?

This project assumes at least namespaces and projects have unique ids across
all cells as many requests need to be routed based on their ID. Since those
tables are across different databases then guaranteeing a unique ID will
require a new solution. There are likely other tables where unique IDs are
necessary and depending on how we resolve routing for GraphQL and other APIs
and other design goals it may be determined that we want the primary key to be
unique for all tables.
