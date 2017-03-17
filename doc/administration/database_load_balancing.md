# Database Load Balancing

GitLab Enterprise Edition allows you to distribute read-only queries amongst
multiple database servers. This can be used to reduce the load on the primary
database, and increase responsiveness.

For load balancing to work you will need at least PostgreSQL 9.2 or newer, MySQL
is not supported. You also need to make sure that you have at least 1 secondary
in [hot standby][hot-standby] mode.

Load balancing also requires that the hosts configured in `config/database.yml`
**always** point to the primary, even after a database failover. Furthermore,
the additional hosts to balance load amongst must **always** point to secondary
databases. This means that you should put a load balance in front of every
database, and have GitLab connect to those load balancers.

For example, say you have a primary ("db1.gitlab.com") and two secondaries,
"db2.gitlab.com" and "db3.gitlab.com". For this setup you will need to have 3
load balancers, one for every host. For example:

* primary.gitlab.com forwards to db1.gitlab.com
* secondary1.gitlab.com forwards to db2.gitlab.com
* secondary2.gitlab.com forwards to db3.gitlab.com

Now let's say that a failover happens and db2 becomes the new primary. This
means forwarding should now happen as follows:

* primary.gitlab.com forwards to db2.gitlab.com
* secondary1.gitlab.com forwards to db1.gitlab.com
* secondary2.gitlab.com forwards to db3.gitlab.com

GitLab does not take care of this for you, so you will need to do so yourself.

Finally, load balancing requires that GitLab can connect to all hosts using the
same credentials and port as configured in `config/database.yml`. Using
different ports or credentials for different hosts is not supported.

## Enabling Load Balancing

Load balancing is configured in `config/database.yml`. For the environment in
which you want to use load balancing you'll need to add the following:

```yaml
load_balancing:
  hosts:
    - host1
    - host2
    - etc
```

For example, for the "production" environment:

```yaml
production:
  username: gitlab
  database: gitlab
  encoding: unicode
  load_balancing:
    hosts:
      - host1.example.com
      - host2.example.com
```

This will balance the load between `host1.example.com` and `host2.example.com`.

## Balancing Queries

Read-only `SELECT` queries will be balanced amongst all the secondary hosts.
Everything else (including transactions) will be executed on the primary.
Queries such as `SELECT ... FOR UPDATE` are also executed on the primary.

## Prepared Statements

Prepared statements don't work well with load balancing and are disabled
automatically when load balancing is enabled. This should have no impact on
response timings.

## Primary Sticking

After a write has been performed GitLab will stick to using the primary for a
certain period of time, scoped to the user that performed the write. GitLab will
revert back to using secondaries when they have either caught up, or after 30
seconds.

## Failover Handling

In the event of a failover or an unresponsive database, the load balancer will
try to use the next available host. If no secondaries are available the
operation is performed on the primary instead.

In the event of a connection error being produced when writing data, the
operation will be retried up to 3 times using an exponential back-off.

When using load balancing you should be able to safely restart a database server
without it immediately leading to errors being presented to the users.

## Logging

The load balancer logs various messages, such as:

* When a host is marked as offline
* When a host comes back online
* When all secondaries are offline

Each log message contains the tag `[DB-LB]` to make searching/filtering of such
log entries easier.

[hot-standby]: https://www.postgresql.org/docs/9.6/static/hot-standby.html
