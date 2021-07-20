---
stage: Enablement
group: Database
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: reference
---

# PostgreSQL

This page contains information about PostgreSQL the GitLab Support team uses
when troubleshooting. GitLab makes this information public, so that anyone can
make use of the Support team's collected knowledge.

WARNING:
Some procedures documented here may break your GitLab instance. Use at your
own risk.

If you're on a [paid tier](https://about.gitlab.com/pricing/) and aren't sure
how to use these commands, [contact Support](https://about.gitlab.com/support/)
for assistance with any issues you're having.

## Other GitLab PostgreSQL documentation

This section is for links to information elsewhere in the GitLab documentation.

### Procedures

- [Connect to the PostgreSQL console](https://docs.gitlab.com/omnibus/settings/database.html#connecting-to-the-bundled-postgresql-database).

- [Omnibus database procedures](https://docs.gitlab.com/omnibus/settings/database.html) including:
  - SSL: enabling, disabling, and verifying.
  - Enabling Write Ahead Log (WAL) archiving.
  - Using an external (non-Omnibus) PostgreSQL installation; and backing it up.
  - Listening on TCP/IP as well as or instead of sockets.
  - Storing data in another location.
  - Destructively reseeding the GitLab database.
  - Guidance around updating packaged PostgreSQL, including how to stop it
    from happening automatically.

- [Information about external PostgreSQL](../postgresql/external.md).

- [Running Geo with external PostgreSQL](../geo/setup/external_database.md).

- [Upgrades when running PostgreSQL configured for HA](https://docs.gitlab.com/omnibus/settings/database.html#upgrading-a-gitlab-ha-cluster).

- Consuming PostgreSQL from [within CI runners](../../ci/services/postgres.md).

- [Using Slony to update PostgreSQL](../../update/upgrading_postgresql_using_slony.md).
  - Uses replication to handle PostgreSQL upgrades if the schemas are the same.
  - Reduces downtime to a short window for switching to the newer version.

- Managing Omnibus PostgreSQL versions [from the development docs](https://docs.gitlab.com/omnibus/development/managing-postgresql-versions.html).

- [PostgreSQL scaling](../postgresql/replication_and_failover.md)
  - Including [troubleshooting](../postgresql/replication_and_failover.md#troubleshooting)
    `gitlab-ctl patroni check-leader` and PgBouncer errors.

- [Developer database documentation](../../development/index.md#database-guides),
  some of which is absolutely not for production use. Including:
  - Understanding EXPLAIN plans.

### Troubleshooting/Fixes

- [GitLab database requirements](../../install/requirements.md#database),
  including
  - Support for MySQL was removed in GitLab 12.1; [migrate to PostgreSQL](../../update/mysql_to_postgresql.md).
  - Required extension: `pg_trgm`
  - Required extension: `btree_gist`

- Errors like this in the `production/sidekiq` log; see:
  [Set default_transaction_isolation into read committed](https://docs.gitlab.com/omnibus/settings/database.html#set-default_transaction_isolation-into-read-committed):

  ```plaintext
  ActiveRecord::StatementInvalid PG::TRSerializationFailure: ERROR:  could not serialize access due to concurrent update
  ```

- PostgreSQL HA [replication slot errors](https://docs.gitlab.com/omnibus/settings/database.html#troubleshooting-upgrades-in-an-ha-cluster):

  ```plaintext
  pg_basebackup: could not create temporary replication slot "pg_basebackup_12345": ERROR:  all replication slots are in use
  HINT:  Free one or increase max_replication_slots.
  ```

- Geo [replication errors](../geo/replication/troubleshooting.md#fixing-replication-errors) including:

  ```plaintext
  ERROR: replication slots can only be used if max_replication_slots > 0

  FATAL: could not start WAL streaming: ERROR: replication slot "geo_secondary_my_domain_com" does not exist

  Command exceeded allowed execution time

  PANIC: could not write to file 'pg_xlog/xlogtemp.123': No space left on device
  ```

- [Checking Geo configuration](../geo/replication/troubleshooting.md), including:
  - Reconfiguring hosts/ports.
  - Checking and fixing user/password mappings.

- [Common Geo errors](../geo/replication/troubleshooting.md#fixing-common-errors).

## Support topics

### Database deadlocks

References:

- [Issue #1 Deadlocks with GitLab 12.1, PostgreSQL 10.7](https://gitlab.com/gitlab-org/gitlab/-/issues/30528).
- [Customer ticket (internal) GitLab 12.1.6](https://gitlab.zendesk.com/agent/tickets/134307)
  and [Google doc (internal)](https://docs.google.com/document/d/19xw2d_D1ChLiU-MO1QzWab-4-QXgsIUcN5e_04WTKy4).
- [Issue #2 deadlocks can occur if an instance is flooded with pushes](https://gitlab.com/gitlab-org/gitlab/-/issues/33650).
  Provided for context about how GitLab code can have this sort of
  unanticipated effect in unusual situations.

```plaintext
ERROR: deadlock detected
```

Three applicable timeouts are identified in the issue [#1](https://gitlab.com/gitlab-org/gitlab/-/issues/30528); our recommended settings are as follows:

```ini
deadlock_timeout = 5s
statement_timeout = 15s
idle_in_transaction_session_timeout = 60s
```

Quoting from issue [#1](https://gitlab.com/gitlab-org/gitlab/-/issues/30528):

> "If a deadlock is hit, and we resolve it through aborting the transaction after a short period, then the retry mechanisms we already have will make the deadlocked piece of work try again, and it's unlikely we'll deadlock multiple times in a row."

NOTE:
In Support, our general approach to reconfiguring timeouts (applies also to the
HTTP stack) is that it's acceptable to do it temporarily as a workaround. If it
makes GitLab usable for the customer, then it buys time to understand the
problem more completely, implement a hot fix, or make some other change that
addresses the root cause. Generally, the timeouts should be put back to
reasonable defaults after the root cause is resolved.

In this case, the guidance we had from development was to drop deadlock_timeout
or statement_timeout, but to leave the third setting at 60s. Setting
idle_in_transaction protects the database from sessions potentially hanging for
days. There's more discussion in [the issue relating to introducing this timeout on GitLab.com](https://gitlab.com/gitlab-com/gl-infra/production/-/issues/1053).

PostgresSQL defaults:

- `statement_timeout = 0` (never)
- `idle_in_transaction_session_timeout = 0` (never)

Comments in issue [#1](https://gitlab.com/gitlab-org/gitlab/-/issues/30528)
indicate that these should both be set to at least a number of minutes for all
Omnibus GitLab installations (so they don't hang indefinitely). However, 15s
for statement_timeout is very short, and will only be effective if the
underlying infrastructure is very performant.

See current settings with:

```shell
sudo gitlab-rails runner "c = ApplicationRecord.connection ; puts c.execute('SHOW statement_timeout').to_a ;
puts c.execute('SHOW deadlock_timeout').to_a ;
puts c.execute('SHOW idle_in_transaction_session_timeout').to_a ;"
```

It may take a little while to respond.

```ruby
{"statement_timeout"=>"1min"}
{"deadlock_timeout"=>"0"}
{"idle_in_transaction_session_timeout"=>"1min"}
```

These settings can be updated in `/etc/gitlab/gitlab.rb` with:

```ruby
postgresql['deadlock_timeout'] = '5s'
postgresql['statement_timeout'] = '15s'
postgresql['idle_in_transaction_session_timeout'] = '60s'
```

Once saved, [reconfigure GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure) for the changes to take effect.

NOTE:
These are Omnibus GitLab settings. If an external database, such as a customer's PostgreSQL installation or Amazon RDS is being used, these values don't get set, and would have to be set externally.
