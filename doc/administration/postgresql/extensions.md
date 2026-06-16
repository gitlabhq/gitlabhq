---
stage: Data Access
group: Database Operations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Manage PostgreSQL extensions
description: Install required and recommended PostgreSQL extensions for GitLab Self-Managed.
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

GitLab requires specific PostgreSQL extensions in every database. For the list of required
extensions and minimum GitLab versions, see
[PostgreSQL requirements](../../install/requirements.md#extensions).

To install extensions, PostgreSQL requires superuser privileges. The GitLab database user
is typically not a superuser, so you must install extensions manually before upgrading GitLab.

## Install required extensions

1. Connect to the GitLab PostgreSQL database using a superuser, for example:

   ```shell
   sudo gitlab-psql -d gitlabhq_production
   ```

1. Install the extension (`btree_gist` in this example) using
   [`CREATE EXTENSION`](https://www.postgresql.org/docs/16/sql-createextension.html):

   ```sql
   CREATE EXTENSION IF NOT EXISTS btree_gist
   ```

1. Verify installed extensions:

   ```shell
   gitlabhq_production=# \dx
   ```

On some systems you may need to install an additional package (for example,
`postgresql-contrib`) for certain extensions to become available.

## Enable pg_stat_statements

`pg_stat_statements` is recommended for troubleshooting slow database queries.
Enabling it requires superuser privileges and a PostgreSQL restart.

1. Add `pg_stat_statements` to `shared_preload_libraries` in `postgresql.conf`.
   For Linux package installations, add the following to `/etc/gitlab/gitlab.rb`:

   ```ruby
   postgresql['shared_preload_libraries'] = 'pg_stat_statements'
   ```

1. Restart PostgreSQL.
1. Create the extension as a superuser:

   ```sql
   CREATE EXTENSION IF NOT EXISTS pg_stat_statements
   ```

For more information, see
[Enable optional query statistics data](../raketasks/maintenance.md#enable-optional-query-statistics-data).

## Troubleshooting

When working with PostgreSQL extensions, you might encounter the following issue.

### Migration fails because an extension is missing

If a database migration fails because an extension is missing, install it manually as a
superuser, then re-run migrations:

```shell
sudo gitlab-rake db:migrate
```
