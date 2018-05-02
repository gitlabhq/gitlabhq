# Database Load Balancing **[PREMIUM ONLY]**

> [Introduced][ee-1283] in [GitLab Premium][eep] 9.0.

Distribute read-only queries among multiple database servers.

## Overview

Database load balancing improves the distribution of database workloads across
multiple computing resources. Load balancing aims to optimize resource use,
maximize throughput, minimize response time, and avoid overload of any single
resource. Using multiple components with load balancing instead of a single
component may increase reliability and availability through redundancy.
[_Wikipedia article_][wikipedia]

When database load balancing is enabled in GitLab, the load is balanced using
a simple round-robin algorithm, without any external dependencies such as Redis.
Load balancing is not enabled for Sidekiq as this would lead to consistency
problems, and Sidekiq mostly performs writes anyway.

In the following image, you can see the load is balanced rather evenly among
all the secondaries (`db4`, `db5`, `db6`). Because `SELECT` queries are not
sent to the primary (unless necessary), the primary (`db3`) hardly has any load.

![DB load balancing graph](img/db_load_balancing_postgres_stats.png)

## Requirements

For load balancing to work you will need at least PostgreSQL 9.2 or newer,
[**MySQL is not supported**][db-req]. You also need to make sure that you have
at least 1 secondary in [hot standby][hot-standby] mode.

Load balancing also requires that the configured hosts **always** point to the
primary, even after a database failover. Furthermore, the additional hosts to
balance load among must **always** point to secondary databases. This means that
you should put a load balance in front of every database, and have GitLab connect
to those load balancers.

For example, say you have a primary (`db1.gitlab.com`) and two secondaries,
`db2.gitlab.com` and `db3.gitlab.com`. For this setup you will need to have 3
load balancers, one for every host. For example:

* `primary.gitlab.com` forwards to `db1.gitlab.com`
* `secondary1.gitlab.com` forwards to `db2.gitlab.com`
* `secondary2.gitlab.com` forwards to `db3.gitlab.com`

Now let's say that a failover happens and db2 becomes the new primary. This
means forwarding should now happen as follows:

* `primary.gitlab.com` forwards to `db2.gitlab.com`
* `secondary1.gitlab.com` forwards to `db1.gitlab.com`
* `secondary2.gitlab.com` forwards to `db3.gitlab.com`

GitLab does not take care of this for you, so you will need to do so yourself.

Finally, load balancing requires that GitLab can connect to all hosts using the
same credentials and port as configured in the
[Enabling load balancing](#enabling-load-balancing) section. Using
different ports or credentials for different hosts is not supported.

## Use cases

- For GitLab instances with thousands of users and high traffic, you can use
  database load balancing to reduce the load on the primary database and
  increase responsiveness, thus resulting in faster page load inside GitLab.

## Enabling load balancing

For the environment in which you want to use load balancing, you'll need to add
the following. This will balance the load between `host1.example.com` and
`host2.example.com`.

**In Omnibus installations:**

1. Edit `/etc/gitlab/gitlab.rb` and add the following line:

    ```ruby
    gitlab_rails['db_load_balancing'] = { 'hosts' => ['host1.example.com', 'host2.example.com'] }
    ```

1. Save the file and [reconfigure GitLab][] for the changes to take effect.

---

**In installations from source:**

1. Edit `/home/git/gitlab/config/database.yml` and add or amend the following lines:

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

1. Save the file and [restart GitLab][] for the changes to take effect.

## Balancing queries

Read-only `SELECT` queries will be balanced among all the secondary hosts.
Everything else (including transactions) will be executed on the primary.
Queries such as `SELECT ... FOR UPDATE` are also executed on the primary.

## Prepared statements

Prepared statements don't work well with load balancing and are disabled
automatically when load balancing is enabled. This should have no impact on
response timings.

## Primary sticking

After a write has been performed, GitLab will stick to using the primary for a
certain period of time, scoped to the user that performed the write. GitLab will
revert back to using secondaries when they have either caught up, or after 30
seconds.

## Failover handling

In the event of a failover or an unresponsive database, the load balancer will
try to use the next available host. If no secondaries are available the
operation is performed on the primary instead.

In the event of a connection error being produced when writing data, the
operation will be retried up to 3 times using an exponential back-off.

When using load balancing, you should be able to safely restart a database server
without it immediately leading to errors being presented to the users.

## Logging

The load balancer logs various messages, such as:

* When a host is marked as offline
* When a host comes back online
* When all secondaries are offline

Each log message contains the tag `[DB-LB]` to make searching/filtering of such
log entries easier. For example:

```
[DB-LB] Host 10.123.2.5 came back online
[DB-LB] Marking host 10.123.2.7 as offline
[DB-LB] Marking host 10.123.2.7 as offline
[DB-LB] Marking host 10.123.2.7 as offline
[DB-LB] Marking host 10.123.2.7 as offline
[DB-LB] Marking host 10.123.2.7 as offline
[DB-LB] Host 10.123.2.6 came back online
[DB-LB] Marking host 10.123.2.7 as offline
[DB-LB] Marking host 10.123.2.7 as offline
[DB-LB] Marking host 10.123.2.7 as offline
[DB-LB] Host 10.123.2.7 came back online
[DB-LB] Host 10.123.2.7 came back online
```

## Handling Stale Reads

> [Introduced][ee-3526] in [GitLab Premium][eep] 10.3.

To prevent reading from an outdated secondary the load balancer will check if it
is in sync with the primary. If the data is determined to be recent enough the
secondary can be used, otherwise it will be ignored. To reduce the overhead of
these checks we only perform these checks at certain intervals.

There are three configuration options that influence this behaviour:

| Option                       | Description                                                                                                    | Default    |
|------------------------------|----------------------------------------------------------------------------------------------------------------|------------|
| `max_replication_difference` | The amount of data (in bytes) a secondary is allowed to lag behind when it hasn't replicated data for a while. | 8 MB       |
| `max_replication_lag_time`   | The maximum number of seconds a secondary is allowed to lag behind before we stop using it.                    | 60 seconds |
| `replica_check_interval`     | The minimum number of seconds we have to wait before checking the status of a secondary.                       | 60 seconds |

The defaults should be sufficient for most users. Should you want to change them
you can specify them in `config/database.yml` like so:

```yaml
production:
  username: gitlab
  database: gitlab
  encoding: unicode
  load_balancing:
    hosts:
      - host1.example.com
      - host2.example.com
    max_replication_difference: 16777216 # 16 MB
    max_replication_lag_time: 30
    replica_check_interval: 30
```

[hot-standby]: https://www.postgresql.org/docs/9.6/static/hot-standby.html
[ee-1283]: https://gitlab.com/gitlab-org/gitlab-ee/merge_requests/1283
[eep]: https://about.gitlab.com/products/
[reconfigure gitlab]: restart_gitlab.md#omnibus-gitlab-reconfigure "How to reconfigure Omnibus GitLab"
[restart gitlab]: restart_gitlab.md#installations-from-source "How to restart GitLab"
[wikipedia]: https://en.wikipedia.org/wiki/Load_balancing_(computing)
[db-req]: ../install/requirements.md#database
[ee-3526]: https://gitlab.com/gitlab-org/gitlab-ee/merge_requests/3526
