---
stage: Data Access
group: Database Operations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Configuring PostgreSQL for scaling
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

In this section, you are guided through configuring a PostgreSQL database to
be used with GitLab in one of our [reference architectures](../reference_architectures/_index.md).

## Configuration options

Choose one of the following PostgreSQL configuration options:

### Standalone PostgreSQL for Linux package installations

This setup is for when you have installed GitLab by using the
[Linux package](https://about.gitlab.com/install/) (CE or EE),
to use the bundled PostgreSQL having only its service enabled.

Read how to [set up a standalone PostgreSQL instance](standalone.md) for Linux package installations.

### Provide your own PostgreSQL instance

This setup is for when you have installed GitLab using the
[Linux package](https://about.gitlab.com/install/) (CE or EE),
or [self-compiled](../../install/installation.md) your installation, but you want to use
your own external PostgreSQL server.

Read how to [set up an external PostgreSQL instance](external.md).

When setting up an external database there are some metrics that are useful for monitoring and troubleshooting.
When setting up an external database there are monitoring and logging settings required for troubleshooting various database related issues.
Read more about [monitoring and logging setup for external Databases](external_metrics.md).

### PostgreSQL replication and failover for Linux package installations

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab Self-Managed

This setup is for when you have installed GitLab using the
[Linux **Enterprise Edition** (EE) package](https://about.gitlab.com/install/?version=ee).

All the tools that are needed like PostgreSQL, PgBouncer, and Patroni are bundled in
the package, so you can use it to set up the whole PostgreSQL infrastructure (primary, replica).

Read how to [set up PostgreSQL replication and failover](replication_and_failover.md) for Linux package installations.

## Related topics

- [Working with the bundled PgBouncer service](pgbouncer.md)
- [Database load balancing](database_load_balancing.md)
- [Moving GitLab databases to a different PostgreSQL instance](moving.md)
- [Multiple databases](multiple_databases.md)
- [Database guides for GitLab development](../../development/database/_index.md)
- [Upgrade external database](external_upgrade.md)
- [Upgrading operating systems for PostgreSQL](upgrading_os.md)
