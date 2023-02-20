---
stage: Data Stores
group: Database
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Configuring PostgreSQL for scaling **(FREE SELF)**

In this section, you are guided through configuring a PostgreSQL database to
be used with GitLab in one of our [reference architectures](../reference_architectures/index.md).

## Configuration options

Choose one of the following PostgreSQL configuration options:

### Standalone PostgreSQL using Omnibus GitLab

This setup is for when you have installed the
[Omnibus GitLab packages](https://about.gitlab.com/install/) (CE or EE),
to use the bundled PostgreSQL having only its service enabled.

Read how to [set up a standalone PostgreSQL instance](standalone.md) using Omnibus GitLab.

### Provide your own PostgreSQL instance

This setup is for when you have installed GitLab using the
[Omnibus GitLab packages](https://about.gitlab.com/install/) (CE or EE),
or installed it [from source](../../install/installation.md), but you want to use
your own external PostgreSQL server.

Read how to [set up an external PostgreSQL instance](external.md).

### PostgreSQL replication and failover with Omnibus GitLab **(PREMIUM SELF)**

This setup is for when you have installed GitLab using the
[Omnibus GitLab **Enterprise Edition** (EE) package](https://about.gitlab.com/install/?version=ee).

All the tools that are needed like PostgreSQL, PgBouncer, and Patroni are bundled in
the package, so you can use it to set up the whole PostgreSQL infrastructure (primary, replica).

Read how to [set up PostgreSQL replication and failover](replication_and_failover.md) using Omnibus GitLab.

## Related topics

- [Working with the bundled PgBouncer service](pgbouncer.md)
- [Database load balancing](database_load_balancing.md)
- [Moving GitLab databases to a different PostgreSQL instance](moving.md)
- [Multiple databases](multiple_databases.md)
- [Database guides for GitLab development](../../development/database/index.md)
