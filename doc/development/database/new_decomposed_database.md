---
stage: Data Access
group: Database Frameworks
info: Any user with at least the Maintainer role can merge updates to this content. For details, see <https://docs.gitlab.com/development/development_processes/#development-guidelines-review>.
title: Stand up a new decomposed database
---

Use this page to add a brand-new decomposed database to the GitLab Rails
application, end to end. It uses the existing `sec` database as a worked reference so
you can diff your change against a real example.

For background on what decomposition is and the day-to-day rules for working with
more than one database, read [Multiple databases](multiple_databases.md) first.
This page is the "how do I add another one" companion to that reference.

## Data-driven database registry

No central list drives database registration. `Gitlab::Database` discovers the
databases at runtime by globbing two directories:

- `db/database_connections/*.yaml` describes each physical connection
  (see `all_database_connection_files` in
  [`lib/gitlab/database.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/database.rb)).
- `db/gitlab_schemas/*.yaml` describes each logical `gitlab_schema`
  (see `all_gitlab_schema_files` in the same file).

EE also globs the same two directories under `ee/db`.

Everything downstream, such as `all_database_connections`, `all_database_names`,
and `database_base_models`, is built from those files. `has_config?` is the
exception: it reads the connections configured in `config/database.yml`. The key
insight for adding a database: you register it by adding YAML files that the
globs pick up, not by editing a central list. A few places still list the
databases by hand, and
[Add the database to the hardcoded database lists](#add-the-database-to-the-hardcoded-database-lists)
covers them.

The YAML is parsed into structs:

- `db/database_connections/*.yaml` is loaded by
  [`Gitlab::Database::DatabaseConnectionInfo`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/database/database_connection_info.rb).
- `db/gitlab_schemas/*.yaml` is loaded by
  [`Gitlab::Database::GitlabSchemaInfo`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/database/gitlab_schema_info.rb).

## Before you start

A new decomposed database usually goes hand in hand with a decomposition epic that
tracks the data model and rollout. For example, `main` and `ci` were split under
[epic 6168](https://gitlab.com/groups/gitlab-org/-/epics/6168) and `sec` under
[epic 13043](https://gitlab.com/groups/gitlab-org/-/epics/13043). Coordinate with
the Database Frameworks and Tenant Scale groups before you begin.

## Step-by-step checklist

The following steps use a hypothetical database named `foo` with a matching
`gitlab_foo` schema. Substitute your own name throughout. The order matters:
schemas and the connection must exist before the specs that enforce them can pass.

### Add the `gitlab_schema` definitions

Create `db/gitlab_schemas/gitlab_foo.yaml`:

```yaml
name: gitlab_foo
description: Schema for the Foo feature tables.
allow_cross_joins:
  - gitlab_shared
  - gitlab_shared_org
  - gitlab_shared_cell_local
allow_cross_transactions:
  - gitlab_internal
  - gitlab_shared
  - gitlab_shared_org
  - gitlab_shared_cell_local
require_sharding_key: true
sharding_root_tables:
  - projects
  - organizations
  - namespaces
```

If the database also holds cell-local reference data, add a second schema such as
`db/gitlab_schemas/gitlab_foo_cell_local.yaml`, following
`db/gitlab_schemas/gitlab_sec_cell_local.yaml`. Also add
`gitlab_foo_cell_local: :gitlab_foo` to `SCHEMA_MAPPING` in
`lib/gitlab/database/query_analyzers/restrict_allowed_schemas.rb`. Without the
mapping, a migration restricted to `gitlab_foo` raises `DMLAccessDeniedError` when
it writes to a `gitlab_foo_cell_local` table.

### Add the connection definition

Create `db/database_connections/foo.yaml`:

```yaml
name: foo
description: GitLab database holding Foo feature related tables.
gitlab_schemas:
  - gitlab_internal
  - gitlab_shared
  - gitlab_shared_org
  - gitlab_shared_cell_local
  - gitlab_foo
  - gitlab_foo_cell_local # only if you created it
lock_gitlab_schemas:
  - gitlab_main
  - gitlab_main_cell_setting
  - gitlab_main_user
  - gitlab_main_org
  - gitlab_main_cell_local
  - gitlab_main_jh
  - gitlab_ci
  - gitlab_ci_cell_local
  - gitlab_pm
  - gitlab_sec
  - gitlab_sec_cell_local
klass: FooApplicationRecord
# if the Foo database is not configured, use this database
fallback_database: main
uses_load_balancing: true
```

Key fields:

- `gitlab_schemas`: the schemas whose tables live on this database.
- `lock_gitlab_schemas`: schemas that belong to other databases. The
  [`gitlab:db:lock_writes` Rake task](multiple_databases.md#locking-writes-on-the-tables-that-dont-belong-to-the-database-schemas)
  write-locks those tables here so they cannot drift.
- `klass`: the abstract base model that owns this connection
  (see [Add the base model](#add-the-base-model)).
- `fallback_database: main`: when a separate `foo` connection is not configured,
  the Foo schemas map to the `main` connection, so the application can run in
  single-database mode. The models reach `main` through the `has_config?` guard in
  the base model. This field also defines the `dev:copy_db:foo` Rake task.
- `db_dir` is optional and defaults to `db`. Reuse the shared `db` directory
  unless you have a reason not to (see the [shared-migrations gotcha](#reuse-the-shared-migrations-and-structuresql)).

### Register the new schemas on the other databases

For each existing connection, add your new schemas to its `lock_gitlab_schemas`
so those databases lock the Foo tables they must not write to. Edit:

- `db/database_connections/main.yaml`
- `db/database_connections/ci.yaml`
- `db/database_connections/sec.yaml`

Add `gitlab_foo` to each `lock_gitlab_schemas` list. If you created
`gitlab_foo_cell_local`, add it too.

### Add the base model

Create `app/models/foo_application_record.rb`, following
[`app/models/sec_application_record.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/models/sec_application_record.rb):

```ruby
# frozen_string_literal: true

class FooApplicationRecord < ApplicationRecord
  self.abstract_class = true

  connects_to database: { writing: :foo, reading: :foo } if Gitlab::Database.has_config?(:foo)
end
```

The `has_config?(:foo)` guard is what makes single-database mode safe: when no
`foo` connection is configured, the model does not call `connects_to` and instead
inherits `main` through `ApplicationRecord`. Compare
[`app/models/ci/application_record.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/models/ci/application_record.rb),
which uses the same pattern.

### Register the test-table prefix

Add an implicit schema mapping for test tables to `IMPLICIT_GITLAB_SCHEMAS` in
[`lib/gitlab/database/gitlab_schema.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/database/gitlab_schema.rb):

```ruby
'_test_gitlab_foo_' => :gitlab_foo,
```

Order matters in that hash: a prefix that contains another prefix must come first.

### Add the `structure.sql` symlink

Create `db/foo_structure.sql` as a symlink to the shared `db/structure.sql`, the
same way `db/sec_structure.sql` and `db/ci_structure.sql` are symlinks:

```shell
ln -s structure.sql db/foo_structure.sql
```

### Add the connection to the `config/database.yml` templates

`config/database.yml` is not committed. Create a committed template for `foo`, for
example `config/database.yml.decomposed-foo-postgresql`. Base it on
`config/database.yml.decomposed-sec-postgresql`, and add a `foo:` block beside the
`sec:` block for each environment.
Do not set a custom `migrations_paths` or `schema_migrations_path`.
Only `geo` and `embedding` override those. For more information, see
[Reuse the shared migrations and `structure.sql`](#reuse-the-shared-migrations-and-structuresql).

In CI, `setup_database_yml` in `scripts/utils.sh` copies a template to
`config/database.yml`, based on the `DECOMPOSED_DB` and `SEC_DECOMPOSED_DB`
variables. The global `variables` in `.gitlab-ci.yml` set both to `"true"`. To run
CI jobs against `foo`, add a variable such as `FOO_DECOMPOSED_DB` and a branch in
`setup_database_yml` that copies the `foo` template. For your local `config/database.yml`, see
[Run the new database in GDK](#run-the-new-database-in-gdk).

### Add dictionary entries for new tables

Each table records its schema in `db/docs/<table>.yml` under `gitlab_schema`. For
tables you create on `foo`, generate the entries:

```shell
bin/rake gitlab:db:dictionary:generate
```

The task does not set `gitlab_schema`. New entries come out without one and raise
`UnknownSchemaError` until you add `gitlab_schema: gitlab_foo` by hand. For entries
that already exist, the task only adds class names to `classes`, so it never
changes a table's schema. To move an existing table, see
[Move an existing table](#move-an-existing-table).

### Add the database to the hardcoded database lists

These files name `main`, `ci`, and `sec` literally instead of reading the
registry. Add `foo` to each:

- `lib/tasks/gitlab/db.rake`: the `all_databases` array that defines the
  `gitlab:db:migration_testing` tasks. `spec/tasks/gitlab/db_rake_spec.rb` expects
  those tasks for every configured database, so a missing entry fails there.
- `lib/tasks/gitlab/db/truncate_legacy_tables.rake`: a
  `gitlab:db:truncate_legacy_tables:foo` task, following the `sec` task.
- `lib/gitlab/database/tables_truncate.rb`: the list of supported databases.
  Without `foo`, truncating the tables that do not belong on `foo` raises
  `database is not supported`, which blocks the physical split.
- `lib/tasks/gitlab/db/schema_load_fix.rake`: the list of databases the
  workaround applies to.
- `app/workers/loose_foreign_keys/cleanup_worker.rb`: the turbo mode list. Also
  add a `loose_foreign_keys_turbo_mode_foo` ops feature flag next to
  `config/feature_flags/ops/loose_foreign_keys_turbo_mode_sec.yml`.
- `lib/gitlab/sidekiq_limits.rb`: the per-database duration limits. Add an entry
  for `foo`, following `sec_db_duration_limit_per_worker`. Then, in
  `lib/gitlab/application_rate_limiter/labkit_adapter/supported_rate_limits.rb`,
  add a `foo_db_duration_limit_per_worker` rule next to the `sec` rule, and add the
  key to `cost_mode_keys`. Without the rule, the Sidekiq resource usage and
  throttling middlewares raise `KeyError` for every job when their feature flags
  are on. Without the `cost_mode_keys` entry, the limit never applies.
- `lib/gitlab/database/retention_policy.rb`: `ELIGIBLE_SCHEMAS` or
  `EXCLUDED_SCHEMAS`. Add `gitlab_foo`, and `gitlab_foo_cell_local` if you created
  it, in the same merge request as the first `db/docs` entry that uses each one.
  `spec/db/retention_policy_definitions_spec.rb` fails when a `db/docs` schema is
  in neither list. In EE, it also fails when a listed schema has no tables.
- `lib/gitlab/database/health_status/indicators/prometheus_alert_indicator.rb`:
  the special case that gives `sec` its own Prometheus queries, or the `main`
  queries if it has none. Without a `foo` case, or `foo` queries in the
  `prometheus_alert_db_indicators_settings` application setting, the indicator
  returns an unknown signal for `foo`. The shared examples in
  `spec/support/shared_examples/database_health_status_indicators/prometheus_alert_based_shared_examples.rb`
  loop over every configured database and skip only `sec`. Handle `foo` there too,
  or the indicator specs fail with `NoMethodError` after `foo` has its own
  connection.
- The background migration and background operation workers. Each database runs
  its own, so copy the `sec` workers and rename them for `foo`:
  - `app/workers/database/batched_background_migration/sec_database_worker.rb` and
    `sec_execution_worker.rb`
  - `app/workers/database/background_operation/sec_scheduler_worker.rb`,
    `sec_orchestrator_worker.rb`, and their `_cell_local` variants

  The workers read a `FOO_DATABASE_NAME` constant, which you add next to
  `SEC_DATABASE_NAME` in `lib/gitlab/database.rb`. Add their cron entries to
  `config/schedule.yml` beside the `sec` entries. Cron job defaults are no longer in
  `config/initializers/1_settings.rb`. Then run
  `bin/rake gitlab:sidekiq:all_queues_yml:generate`. Without these workers, batched
  background migrations and background operations queued on `foo` never run.

  Two more places name `sec` literally for these workers:

  - `EXEMPT_WORKER_NAMES` in `lib/gitlab/sidekiq_middleware/size_limiter/validator.rb`
    lists `Database::BatchedBackgroundMigration::SecDatabaseWorker`. Add
    `Database::BatchedBackgroundMigration::FooDatabaseWorker`.
  - The `case tracking_database` in
    `spec/support/shared_examples/workers/batched_background_migration_worker_shared_examples.rb`
    has no branch for `foo`. Add one, or the copied worker spec fails with
    `NoMethodError` after `foo` has its own connection.

## Reuse the shared migrations and `structure.sql`

The migration layout is the most common thing to get wrong.

A new decomposed database such as `foo` reuses the shared `db/migrate`,
`db/post_migrate`, and `db/schema_migrations`. It does not get its own
migration directories. Data definition language (DDL) runs against every configured
database. A migration that declares a schema in `restrict_gitlab_migration` is
skipped entirely on databases that do not hold that schema. The shared migrations
are why `db/foo_structure.sql` is a symlink to the single shared `db/structure.sql`.

The exceptions are `geo` and `embedding`, which do have their own
`ee/db/<name>/migrate` directories. Those paths are wired up explicitly in
[`lib/gitlab/patch/database_config.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/patch/database_config.rb),
which only adds custom `migrations_paths` for `embedding` and `geo`. Unless you
are building something like those, do not follow their layout.

For the rules on writing migrations that touch more than one database, see
[Migrations for multiple databases](migrations_for_multiple_databases.md).

## Move an existing table

Prerequisites:

- Decide whether to remove the cross-database dependencies before or after the
  `db/docs` change, as described in
  [Remove cross-database dependencies](#remove-cross-database-dependencies).
- Finalize the in-flight backfills for the table, as described in
  [Backfills already queued against the old schema](#backfills-already-queued-against-the-old-schema).

To move `foo_bar` onto `foo`:

1. In `db/docs/foo_bar.yml`, change `gitlab_schema` to `gitlab_foo`. The
   cross-database checks apply to the table straight away, whether or not `foo` is
   configured. See
   [Checks that enforce database boundaries](#checks-that-enforce-database-boundaries).
1. Change each model that uses the table to inherit from `FooApplicationRecord`
   instead of `ApplicationRecord`. Until it does, the model keeps using the `main`
   connection, even after `foo` is configured. For `sec`, every model on the
   database inherits `SecApplicationRecord`, for example
   `ee/app/models/dast/pre_scan_verification.rb`.
1. Run `bin/rake gitlab:db:dictionary:generate` to refresh `classes` in the entry.
1. Update the released migrations that reference the table, as described in the
   next section.

## Relocate tables that released migrations reference

When you move an existing table onto the new database, you inherit a second
problem: migrations that already shipped still declare the table's old schema.

A data migration declares which schema it may write to:

```ruby
class BackfillFooBarProjectId < Gitlab::Database::Migration[2.2]
  restrict_gitlab_migration gitlab_schema: :gitlab_main_org
end
```

When the `db/docs` entry for `foo_bar` changes from `gitlab_main_org` to
`gitlab_foo`, that declaration is now wrong. The migration is already released, so
it can still run on a GitLab Self-Managed instance upgrading through that version,
and it raises
`Gitlab::Database::QueryAnalyzers::RestrictAllowedSchemas::DMLAccessDeniedError`
when it does.

Update the annotation on the released migration to the new schema, in the same
commit that moves the table's `db/docs` entry. The precedent is
[commit b5b3f96b585a](https://gitlab.com/gitlab-org/gitlab/-/commit/b5b3f96b585a),
where the Secure and Govern decomposition flipped
`QueueBackfillSbomOccurrencesVulnerabilitiesProjectId` from `:gitlab_main_cell`
to `:gitlab_sec` alongside the dictionary change.

Editing a released migration feels wrong, so it is worth being explicit about why
it is not: `restrict_gitlab_migration` is not a historical record of where the
table lived when the migration was written. It is a runtime allow-list, read when
the migration executes, to decide which connection may run its data-manipulation
language. The value has to describe where the table lives now, otherwise the
migration cannot run at all. The schema history lives in `db/structure.sql` and
the migration's own DDL, and neither is touched by this.

The annotation is the failure you can see. Two others are harder to spot, so check
for them deliberately.

### Schemas passed as an argument, not only declared

Some migrations do not only declare the schema in `restrict_gitlab_migration`,
they also pass it to `queue_batched_background_migration`:

```ruby
queue_batched_background_migration(
  MIGRATION,
  :foo_bar,
  :id,
  gitlab_schema: :gitlab_main_org,
  ...
)
```

A stale annotation fails loudly with `DMLAccessDeniedError`, and a red pipeline
finds it. A stale argument can fail silently. The queued row stores the schema you
pass, but `ensure_batched_background_migration_is_finished` and
`finalize_batched_background_migration` look the row up by the schema in
`restrict_gitlab_migration`. When the two differ, neither finds the row.
`finalize_batched_background_migration` raises
`Could not find batched background migration`.
`ensure_batched_background_migration_is_finished` logs a warning and returns as
though the backfill were already finished. It raises only when `DBLAB_ENVIRONMENT`
is set. Grep the moving table's migrations for every `gitlab_schema:` argument and
the annotation, and flip both.

### Backfills already queued against the old schema

`batched_background_migrations` stores a `gitlab_schema` text column, written at
queue time from the schema in force when the job was enqueued. Editing migration
source does not rewrite existing rows. So any backfill already queued for a moving
table keeps the old schema string, and after the `db/docs` change the finder
filters that stored value against the new connection's schemas and can no longer
see the job.

Editing source cannot fix data that is already in the table. Finalize the
in-flight backfills for the moving tables before you change their `db/docs`
entries, so there are no queued rows carrying the old schema. If that is not
possible, the rows have to be corrected as a data migration, or the `db/docs`
change sequenced into a window when none are in flight. Confirm nothing is queued
with a query against `batched_background_migrations` filtered to the moving table
names before you merge the `db/docs` change.

### Other checks when you move a table

Check these things when you move a table:

- Sweep every released migration and background-migration class that touches the
  moving table, not only the most recent one. Grep the table name across
  `db/migrate`, `db/post_migrate`, and `lib/gitlab/background_migration`.
- A migration that touches tables now split across two databases cannot keep a
  single `restrict_gitlab_migration`. Split it, or move the cross-database part to
  application code. See
  [Migrations for multiple databases](migrations_for_multiple_databases.md).
- If `config/initializers/postgres_partitioning.rb` registers the table through
  `register_tables` with `limit_connection_names: %i[main]`, change it to name the
  new connection. Otherwise partition sync skips the new database, and writes
  start failing when the spare partitions run out. Tables registered through
  `register_models` follow the model's connection and need no change. Outside
  production, partition sync also creates partitions on the other connections, so
  a missed entry still looks fine in GDK and CI.
- If Siphon replicates the table, change `database:` in
  `db/siphon/tables/<table>.yml` to `foo`. `spec/db/clickhouse_siphon_tables_spec.rb`
  fails when that database does not hold the table's `gitlab_schema`.
- Workers that call `defer_on_database_health_signal` for the moving table still
  declare the old schema. The health check picks its connection from that schema,
  so after the split it watches the old database, and nothing fails. Grep
  `app/workers` and `ee/app/workers` for `defer_on_database_health_signal` with the
  old schema. For each worker that touches the moving table, change the schema to
  `gitlab_foo`. Some workers list no tables, so a grep for the table name alone
  misses them. For an example, see
  [issue 631673](https://gitlab.com/gitlab-org/gitlab/-/issues/631673).

## Run the new database in GDK

Before you move the data, you must run the specs for the moving tables with `foo`
turned on in GDK. The CI checks do not catch every query on the wrong connection, as
described in
[Checks that enforce database boundaries](#checks-that-enforce-database-boundaries).
While the allowlists still have entries, keep `foo` off day to day, as described
in [Cross-joins and stale copies](#cross-joins-and-stale-copies).

GDK lists each database by hand in these files:

- `lib/gdk/config.rb`
- `support/templates/gitlab/config/database.yml.erb`
- `lib/support/bootstrap_rails.rb`
- `lib/gdk/command/truncate_legacy_tables.rb`
- `lib/gdk/task_helpers/rails_migration.rb`

Until a GDK merge request adds `foo` to them, the `gitlab.rails.databases.foo`
setting does not exist, and `gdk config set` cannot turn on `foo`.

### Before GDK supports the database

To run `foo` before the GDK merge request is merged:

1. Add a `foo:` block to `gitlab/config/database.yml` for each environment,
   following the `sec:` entries.
1. GDK regenerates `gitlab/config/database.yml` from its template and overwrites
   hand edits. It shows a diff and backs up the old file, but your change is gone
   from `config/database.yml`. To keep your change, protect the file in `gdk.yml`:

   ```yaml
   gdk:
     protected_config_files:
       - 'gitlab/config/database.yml'
   ```

1. From the `gitlab` directory, create the database and empty the tables that do
   not belong on it, the same way `bootstrap_sec_db` in GDK does for `sec`:

   ```shell
   bin/rake dev:copy_db:foo
   bin/rake gitlab:db:lock_writes
   bin/rake gitlab:db:truncate_legacy_tables:foo
   bin/rake gitlab:db:unlock_writes
   ```

`dev:copy_db:foo` copies `main`. The task is defined only after you add the
connection definition and `config/database.yml` has a `foo` entry. The truncate
task needs the changes to the hardcoded database lists.

### After GDK supports the database

Remove `gitlab/config/database.yml` from `protected_config_files`. Then set the
flag and run `gdk update`:

```shell
gdk config set gitlab.rails.databases.foo.enabled true
gdk update
```

Use `gdk update` for this first run, not `gdk reconfigure`. `gdk reconfigure`
creates missing databases before it regenerates `config/database.yml`, so it stops
at the missing `dev:copy_db:foo` task and never writes the file. `gdk update`
writes the file first. However, by default `gdk update` also checks out the
default branch in `gitlab/`. While your GitLab changes are still on a branch,
either set `gitlab.auto_update` to `false` before you run `gdk update`, or
regenerate the file from the GDK root and then reconfigure:

```shell
make gitlab/config/database.yml
gdk reconfigure
```

To run in single-database mode instead, set the flag to `false` and run
`gdk reconfigure`. See
[Configure single database](multiple_databases.md#configure-single-database) for
the caveats about switching modes on an existing instance.

### Cross-joins and stale copies

While the cross-database allowlists still have entries, turn on `foo` in GDK only
when you work on removing them or on the final check before you move the data.
With `foo` on, web requests, Sidekiq jobs, and specs raise
`CrossSchemaAccessError` on every remaining cross-join through `main`,
allowlisted or not.

> [!warning]
> In the Rails console, `rails runner`, and most Rake tasks, a cross-database join
> can still return correct-looking results, which hides it. `dev:copy_db` creates
> the new database with `main` as its template. Even if you truncate the tables
> that do not belong on the new database, `main` keeps its copy of the `foo`
> tables, so a join through `main` reads that copy until writes to `foo` make the
> two diverge. Web requests and Sidekiq jobs in GDK raise `CrossSchemaAccessError`
> on the same query instead.

To clear `main`'s copy of the `foo` tables, run the `gitlab:db:lock_writes` Rake
task and then `gitlab:db:truncate_legacy_tables:main`. The truncate task refuses
to run until the tables it truncates are locked for writes. It truncates every
table on `main` that does not belong there, so it also empties `main`'s copies of
the `ci` and `sec` tables.

## Checks that enforce database boundaries

Several specs fail if you miss a step, which is a feature: they stop an
inconsistent database from merging.

- The [database dictionary](database_dictionary.md) requires every table to map to
  a known `gitlab_schema`.
  [`Gitlab::Database::Dictionary`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/database/dictionary.rb)
  raises `UnknownSchemaError` for an unmapped table.
- `spec/db/docs_spec.rb` and `spec/db/schema_spec.rb` verify the dictionary and the
  `structure.sql` are consistent.
- `spec/lib/gitlab/database/gitlab_schema_spec.rb` verifies the schema definitions
  and the implicit test-table prefixes.
- `spec/lib/gitlab/database/database_connection_info_spec.rb` verifies the
  connection YAML parses and resolves its base class.

The previous checks catch a mis-wired registry. Three more fail as soon as you
change a table's `gitlab_schema` in its `db/docs` entry, even if the new database
is not configured. They read each table's schema from the database dictionary, not
from the new database's connection. In
[!130038](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/130038), moving
`notification_settings` from `gitlab_main` to `gitlab_main_cell` (since renamed
`gitlab_main_org`) in its `db/docs` entry was enough to fail the pipeline.

- `spec/support/database/prevent_cross_joins.rb` fails any query that joins tables
  whose schemas are not paired in `allow_cross_joins`.
- `lib/gitlab/database/query_analyzers/prevent_cross_database_modification.rb`
  fails any transaction that modifies tables whose schemas are not paired in
  `allow_cross_transactions`.
- `spec/lib/gitlab/database/no_cross_db_foreign_keys_spec.rb` fails any foreign key
  between tables whose schemas are not paired in `allow_cross_foreign_keys`, unless
  the column is listed in the spec's `allowed_cross_database_foreign_keys`.

`fallback_database` does not change this. It decides which connection serves the
new schema when the database is not configured. That keeps connection-based
analyzers such as `GitlabSchemasValidateConnection` passing, but these three
checks compare schemas only.

A green pipeline on `fallback_database` does not mean the move is done. The three
checks act only on statements that touch more than one `gitlab_schema`, so they
miss a single-table query that runs on the wrong connection. For example,
`ApplicationRecord.legacy_bulk_insert('foo_bar', rows)` inserts through `main`,
because `legacy_bulk_insert` uses the connection of the class you call it on.
With one database, the suite passes. Only `GitlabSchemasValidateConnection`
catches this, and only after `foo` has its own connection. Before you move the
data, run the specs for the moving tables with `foo` turned on, as described in
[Run the new database in GDK](#run-the-new-database-in-gdk).

### Allowlist existing cross-database violations

How you allowlist the existing violations depends on how many there are. When
there are few, allowlist each one where it happens and tie it to an issue:

- Wrap a cross-join in `allow_cross_joins_across_databases`. For examples, see
  [Allowlist for existing cross-joins](multiple_databases.md#allowlist-for-existing-cross-joins).
- Wrap a cross-database transaction in `temporary_ignore_tables_in_transaction`.
  In specs, use `allow_cross_database_modification_within_transaction`. For
  examples, see
  [Fixing cross-database transactions](multiple_databases.md#fixing-cross-database-transactions).
- Add a cross-database foreign key column to `allowed_cross_database_foreign_keys`.
  For examples, see
  [Allowlist for existing cross-database foreign keys](multiple_databases.md#allowlist-for-existing-cross-database-foreign-keys).

When there are thousands, marking each call site is a project of its own. List
the failing spec files in `spec/support/database/cross-join-allowlist.yml` and
`spec/support/database/cross-database-modification-allowlist.yml` instead. The CI
decomposition started with 418 spec files in the first and 1,340 in the second,
and emptied both within a year. CI does not run these checks for a listed spec
file, for any database, so new violations in that file go unnoticed. Treat the
list as a backlog and work through it until it is empty. Foreign keys have no
per-file list, so they always go in `allowed_cross_database_foreign_keys`.

These allowlists cover only the three schema checks. `GitlabSchemasValidateConnection`
does not read them, so it still raises on allowlisted cross-joins after the new
database has its own connection, as described in
[Cross-joins and stale copies](#cross-joins-and-stale-copies). Keep CI on
`fallback_database` until the allowlists are empty.

Do not add the schema the tables are moving from (for example, `gitlab_main_org`)
to the new schema's `allow_cross_joins`, `allow_cross_transactions`, or
`allow_cross_foreign_keys` lists, or add the new schema to that schema's lists.
Either one turns the check off for anything that touches only those two schemas.

## Remove cross-database dependencies

Decide the order of work before you merge the first `db/docs` change. The number
of violations matters more than the number of tables. If there are only a few, for
example because the tables are joined in one place, remove the cross-database
dependencies first and change the `db/docs` entries last. If there are thousands,
even for a few tables, change the `db/docs` entries first. Allowlist the existing
violations with the per-file lists described in
[Allowlist existing cross-database violations](#allowlist-existing-cross-database-violations),
and work through the lists until they are empty. To count the violations before
you decide, change the `db/docs` entries in a draft merge request and read the CI
failures.

Either way, moving the data to the new database comes last. The tables cannot
live on a separate database until you remove every query that joins across the
new boundary, every transaction that writes to both sides, and every foreign key
between them. CI starts reporting them as soon as the `db/docs` entries change.

For joins, see
[Removing joins between `main` and non `main` tables](multiple_databases.md#removing-joins-between-main-and-non-main-tables).
For transactions, see
[Removing cross-database transactions](multiple_databases.md#removing-cross-database-transactions).

Check Import/Export for every moving table, because its writes do not show up in
the models. File-based import and direct transfer both save the relation trees
defined in `lib/gitlab/import_export/*/import_export.yml` through
`Gitlab::ImportExport::Base::RelationObjectSaver`. That class saves each top-level
relation with one `save!` and moves only collection subrelations out of the
transaction. A `has_one` subrelation stays in it, along with its own
collections. For example, importing a merge request writes `merge_requests`,
`merge_request_diffs`, and `merge_request_diff_files` in one transaction. CI
reports it as a cross-database transaction, but grepping the models for the
write finds nothing.

Replace each cross-database foreign key with a loose foreign key, as described in
[Foreign keys that cross databases](multiple_databases.md#foreign-keys-that-cross-databases).
The
[`scripts/decomposition/generate-loose-foreign-key` script](loose_foreign_keys.md#the-scriptsdecompositiongenerate-loose-foreign-key)
writes the loose foreign key definition, the migration that removes the old key,
and the spec updates.

The script does not add the deletion trigger. If the parent table is not tracked
yet, follow [Track record changes](loose_foreign_keys.md#track-record-changes)
first.

## Reference implementation

The `sec` database is the most recent decomposed database and the cleanest example
to diff against. In commit order:

- [Store databases and GitLab schema configuration in YAML](https://gitlab.com/gitlab-org/gitlab/-/commit/f027557fd5c6f9e728abaa9ddf21b5c6d88ccc14):
  the framework that made the registry YAML-glob-driven.
- [Add configuration for sec DB](https://gitlab.com/gitlab-org/gitlab/-/commit/faf789e010b264e31c6db729be8cdff9ed325421):
  adds `db/gitlab_schemas/gitlab_sec.yaml`.
- [Add gitlab_sec db connection and application record](https://gitlab.com/gitlab-org/gitlab/-/commit/c93d2b4e1112ed682c4690fe0c19b78a5dd51141):
  adds the connection YAML and base model, and registers the schema on `main` and `ci`.
- [Rename SecApplicationRecord to Sec::AR](https://gitlab.com/gitlab-org/gitlab/-/commit/77f124b7bc830022b0e80b2300a25e2593e4ffea):
  moves the base model to its current location, `app/models/sec_application_record.rb`.
- [Add gitlab_sec_cell_local schema](https://gitlab.com/gitlab-org/gitlab/-/commit/036bff89c8e3b8450844842c445e4fedb83b2ac7):
  adds the cell-local schema.

Epics:

- [Decompose GitLab.com's database to improve scalability](https://gitlab.com/groups/gitlab-org/-/epics/6168)
- [Decompose Secure and Govern related tables to a separate Postgres DB](https://gitlab.com/groups/gitlab-org/-/epics/13043)
