# pg_ash (vendored)

This directory holds a verbatim copy of the pg_ash install script. pg_ash is
Active Session History for PostgreSQL: it samples `pg_stat_activity` and rolls
the samples up so you can see what the database was busy with in the past.

## Provenance

- **Upstream:** <https://github.com/NikolayS/pg_ash>
- **Pinned commit:** `083e9c163965c5c8175a16c6d172609898c7291c` (2026-07-29)
- **Version:** 2.0 beta 1
- **License:** Apache-2.0 (see `LICENSE`)

`ash-install.sql` is a verbatim copy of upstream `sql/ash-install.sql`. Do not
edit it here.

To refresh to a new upstream version:

1. Copy `sql/ash-install.sql` and `LICENSE` from upstream at your chosen commit
   into this directory.
2. Update the pinned commit, its date, and version in the Provenance list above.
3. Update `Gitlab::Database::PgAsh::VENDORED_VERSION` to match. The version
   string is the default value of the `version` column in the `ash.config` table
   definition inside `ash-install.sql`.

Automated license checks do not cover files copied into the tree by hand, so any
refresh needs a manual license check as well. See
[the licensing guide](../../doc/development/licensing.md).

## How it is installed

An administrator installs pg_ash on purpose. No migration applies it, and
nothing applies it at boot:

```shell
bundle exec rake gitlab:db:pg_ash:install
bundle exec rake gitlab:db:pg_ash:status
bundle exec rake gitlab:db:pg_ash:uninstall   # drops the schema and all data
```

The script is pure SQL and PL/pgSQL. It needs no C extension, no
`shared_preload_libraries` entry, and no server restart.

## Re-running install, and why it is not an upgrade

Running `install` again with the same vendored version is a no-op. Tables use
`create ... if not exists`; functions are dropped and recreated (existing
EXECUTE grants are snapshotted and re-applied), leaving the collected samples,
the `ash.config` settings and `installed_at` untouched. It runs inside a single
transaction, so a failure part-way rolls back and re-running after one is safe.

## Why the schema is invisible to the schema tooling

pg_ash puts its objects in a Postgres schema named `ash`, which is not part of
`Gitlab::Database::EXTRA_SCHEMAS` and has no `db/docs` entries. Two consequences:

- Statements against `ash` have to run with the query analyzers suppressed.
  `Gitlab::Database::PgAsh::Installer` does this.
- `ash` is outside the Rails search path, so the dictionary specs never see its
  tables. Only `spec/db/schema_spec.rb`, which counts schemas, would notice, and
  it does not, because CI never installs pg_ash.
