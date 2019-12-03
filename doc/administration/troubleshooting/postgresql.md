---
type: reference
---

# PostgreSQL

This page is useful information about PostgreSQL that the GitLab Support
Team sometimes uses while troubleshooting. GitLab is making this public, so that anyone
can make use of the Support team's collected knowledge.

CAUTION: **Caution:** Some procedures documented here may break your GitLab instance. Use at your own risk.

If you are on a [paid tier](https://about.gitlab.com/pricing/) and are not sure how
to use these commands, it is best to [contact Support](https://about.gitlab.com/support/)
and they will assist you with any issues you are having.

## Other GitLab PostgreSQL documentation

This section is for links to information elsewhere in the GitLab documentation.

### Procedures

- [Connect to the PostgreSQL console.](https://docs.gitlab.com/omnibus/settings/database.html#connecting-to-the-bundled-postgresql-database)

- [Omnibus database procedures](https://docs.gitlab.com/omnibus/settings/database.html) including
  - SSL: enabling, disabling, and verifying.
  - Enabling Write Ahead Log (WAL) archiving.
  - Using an external (non-Omnibus) PostgreSQL installation; and backing it up.
  - Listening on TCP/IP as well as or instead of sockets.
  - Storing data in another location.
  - Destructively reseeding the GitLab database.
  - Guidance around updating packaged PostgreSQL, including how to stop it happening automatically.

- [More about external PostgreSQL](../external_database.md)

- [Running GEO with external PostgreSQL](../geo/replication/external_database.md)

- [Upgrades when running PostgreSQL configured for HA.](https://docs.gitlab.com/omnibus/settings/database.html#upgrading-a-gitlab-ha-cluster)

- Consuming PostgreSQL from [within CI runners](../../ci/services/postgres.md)

- [Using Slony to update PostgreSQL](../../update/upgrading_postgresql_using_slony.md)
  - Uses replication to handle PostgreSQL upgrades - providing the schemas are the same.
  - Reduces downtime to a short window for swinging over to the newer vewrsion.

- Managing Omnibus PostgreSQL versions [from the development docs](https://docs.gitlab.com/omnibus/development/managing-postgresql-versions.html)

- [PostgreSQL scaling and HA](../high_availability/database.md)
  - including [troubleshooting](../high_availability/database.md#troubleshooting) `gitlab-ctl repmgr-check-master` and PgBouncer errors

- [Developer database documentation](../../development/README.md#database-guides) - some of which is absolutely not for production use. Including:
  - understanding EXPLAIN plans

### Troubleshooting/Fixes

- [GitLab database requirements](../../install/requirements.md#database) including
  - Support for MySQL was removed in GitLab 12.1; [migrate to PostgreSQL](../../update/mysql_to_postgresql.md)
  - required extension pg_trgm
  - required extension postgres_fdw for Geo

- Errors like this in the `production/sidekiq` log; see: [Set default_transaction_isolation into read committed](https://docs.gitlab.com/omnibus/settings/database.html#set-default_transaction_isolation-into-read-committed):

  ```plaintext
  ActiveRecord::StatementInvalid PG::TRSerializationFailure: ERROR:  could not serialize access due to concurrent update
  ```

- PostgreSQL HA - [replication slot errors](https://docs.gitlab.com/omnibus/settings/database.html#troubleshooting-upgrades-in-an-ha-cluster):

  ```plaintext
  pg_basebackup: could not create temporary replication slot "pg_basebackup_12345": ERROR:  all replication slots are in use
  HINT:  Free one or increase max_replication_slots.
  ```

- GEO [replication errors](../geo/replication/troubleshooting.md#fixing-replication-errors) including:

  ```plaintext
  ERROR: replication slots can only be used if max_replication_slots > 0

  FATAL: could not start WAL streaming: ERROR: replication slot “geo_secondary_my_domain_com” does not exist

  Command exceeded allowed execution time

  PANIC: could not write to file ‘pg_xlog/xlogtemp.123’: No space left on device
  ```

- [Checking GEO configuration](../geo/replication/troubleshooting.md#checking-configuration) including
  - reconfiguring hosts/ports
  - checking and fixing user/password mappings

- [Common GEO errors](../geo/replication/troubleshooting.md#fixing-common-errors)

## Support topics

### Database deadlocks

References:

- [Issue #1 Deadlocks with GitLab 12.1, PostgreSQL 10.7](https://gitlab.com/gitlab-org/gitlab/issues/30528)
- [Customer ticket (internal) GitLab 12.1.6](https://gitlab.zendesk.com/agent/tickets/134307) and [Google doc (internal)](https://docs.google.com/document/d/19xw2d_D1ChLiU-MO1QzWab-4-QXgsIUcN5e_04WTKy4)
- [Issue #2 deadlocks can occur if an instance is flooded with pushes](https://gitlab.com/gitlab-org/gitlab/issues/33650). Provided for context about how GitLab code can have this sort of unanticipated effect in unusual situations.

```
ERROR: deadlock detected
```

Three applicable timeouts are identified in the issue [#1](https://gitlab.com/gitlab-org/gitlab/issues/30528); our recommended settings are as follows:

```
deadlock_timeout = 5s
statement_timeout = 15s
idle_in_transaction_session_timeout = 60s
```

Quoting from from issue [#1](https://gitlab.com/gitlab-org/gitlab/issues/30528):

> "If a deadlock is hit, and we resolve it through aborting the transaction after a short period, then the retry mechanisms we already have will make the deadlocked piece of work try again, and it's unlikely we'll deadlock multiple times in a row."

TIP: **Tip:** In support, our general approach to reconfiguring timeouts (applies also to the HTTP stack as well) is that it's acceptable to do it temporarily as a workaround. If it makes GitLab usable for the customer, then it buys time to understand the problem more completely, implement a hot fix, or make some other change that addresses the root cause. Generally, the timeouts should be put back to reasonable defaults once the root cause is resolved.

In this case, the guidance we had from development was to drop deadlock_timeout and/or statement_timeout but to leave the third setting at 60s. Setting idle_in_transaction protects the database from sessions potentially hanging for days. There's more discussion in [the issue relating to introducing this timeout on GitLab.com](https://gitlab.com/gitlab-com/gl-infra/production/issues/1053).

PostgresSQL defaults:

- statement_timeout = 0 (never)
- idle_in_transaction_session_timeout = 0 (never)

Comments in issue [#1](https://gitlab.com/gitlab-org/gitlab/issues/30528) indicate that these should both be set to at least a number of minutes for all Omnibus installations (so they don't hang indefinitely). However, 15s for statement_timeout is very short, and will only be effective if the underlying infrastructure is very performant.

See current settings with:

```
sudo gitlab-rails runner "c = ApplicationRecord.connection ; puts c.execute('SHOW statement_timeout').to_a ;
puts c.execute('SHOW lock_timeout').to_a ;
puts c.execute('SHOW idle_in_transaction_session_timeout').to_a ;"
```

It may take a little while to respond.

```
{"statement_timeout"=>"1min"}
{"lock_timeout"=>"0"}
{"idle_in_transaction_session_timeout"=>"1min"}
```

NOTE: **Note:**
These are Omnibus settings. If an external database, such as a customer's PostgreSQL installation or Amazon RDS is being used, these values don't get set, and would have to be set externally.
