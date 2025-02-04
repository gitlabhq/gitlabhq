---
stage: Tenant Scale
group: Cells Infrastructure
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Multiple Databases
---

To allow GitLab to scale further we
[decomposed the GitLab application database into multiple databases](https://gitlab.com/groups/gitlab-org/-/epics/6168).
The main databases are `main`, `ci`, and (optionally) `sec`. GitLab supports being run with one, two, or three databases.
On GitLab.com we are using separate `main` and `ci` databases.

For the purpose of building the [Cells](https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/cells/) architecture, we are decomposing
the databases further, to introduce another database `gitlab_main_clusterwide`.

## GitLab Schema

For properly discovering allowed patterns between different databases
the GitLab application implements the [database dictionary](database_dictionary.md).

The database dictionary provides a virtual classification of tables into a `gitlab_schema`
which conceptually is similar to [PostgreSQL Schema](https://www.postgresql.org/docs/current/ddl-schemas.html).
We decided as part of [using database schemas to better isolated CI decomposed features](https://gitlab.com/gitlab-org/gitlab/-/issues/333415)
that we cannot use PostgreSQL schema due to complex migration procedures. Instead we implemented
the concept of application-level classification.
Each table of GitLab needs to have a `gitlab_schema` assigned:

| Database | Description | Notes |
| -------- | ----------- | ------- |
| `gitlab_main`| All tables that are being stored in the `main:` database. | Currently, this is being replaced with `gitlab_main_cell`, for the purpose of building the [Cells](https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/cells/) architecture. `gitlab_main_cell` schema describes all tables that are local to a cell in a GitLab installation. For example, `projects` and `groups` |
| `gitlab_main_clusterwide` | All tables where all rows, or a subset of rows needs to be present across the cluster, in the [Cells](https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/cells/) architecture. For example, `users` and `application_settings`.| For the [Cells 1.0 architecture](https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/cells/iterations/cells-1.0/), there are no real clusterwide tables as each cell will have its own database. In effect, these tables will still be stored locally in each cell. |
| `gitlab_ci` | All CI tables that are being stored in the `ci:` database (for example, `ci_pipelines`, `ci_builds`) | |
| `gitlab_geo` | All Geo tables that are being stored in the `geo:` database (for example, like `project_registry`, `secondary_usage_data`) | |
| `gitlab_shared` | All application tables that contain data across all decomposed databases (for example, `loose_foreign_keys_deleted_records`) for models that inherit from `Gitlab::Database::SharedModel`. | |
| `gitlab_internal` | All internal tables of Rails and PostgreSQL (for example, `ar_internal_metadata`, `schema_migrations`, `pg_*`) | |
| `gitlab_pm` | All tables that store `package_metadata`| It is an alias for `gitlab_main`, to be replaced with `gitlab_sec` |
| `gitlab_sec` | All Security and Vulnerability feature tables to be stored in the `sec:` database | [Decomposition in progress](https://gitlab.com/groups/gitlab-org/-/epics/13043) |

More schemas to be introduced with additional decomposed databases

The usage of schema enforces the base class to be used:

- `ApplicationRecord` for `gitlab_main`/`gitlab_main_cell.`
- `Ci::ApplicationRecord` for `gitlab_ci`
- `Geo::TrackingBase` for `gitlab_geo`
- `Gitlab::Database::SharedModel` for `gitlab_shared`
- `PackageMetadata::ApplicationRecord` for `gitlab_pm`
- `Gitlab::Database::SecApplicationRecord` for `gitlab_sec`

### Choose either the `gitlab_main_cell` or `gitlab_main_clusterwide` schema

This content has been moved to a
[new location](../cells/_index.md#choose-either-the-gitlab_main_cell-or-gitlab_main_clusterwide-schema)

### Defining a sharding key for all cell-local tables

This content has been moved to a
[new location](../cells/_index.md#defining-a-sharding-key-for-all-cell-local-tables)

### The impact of `gitlab_schema`

The usage of `gitlab_schema` has a significant impact on the application.
The `gitlab_schema` primary purpose is to introduce a barrier between different data access patterns.

This is used as a primary source of classification for:

- [Discovering cross-joins across tables from different schemas](#removing-joins-between-ci-and-non-ci-tables)
- [Discovering cross-database transactions across tables from different schemas](#removing-cross-database-transactions)

### The special purpose of `gitlab_shared`

`gitlab_shared` is a special case that describes tables or views that, by design, contain data across
all decomposed databases. This classification describes application-defined tables (like `loose_foreign_keys_deleted_records`).

**Be careful** to use `gitlab_shared` as it requires special handling while accessing data.
Since `gitlab_shared` shares not only structure but also data, the application needs to be written in a way
that traverses all data from all databases in sequential manner.

```ruby
Gitlab::Database::EachDatabase.each_model_connection([MySharedModel]) do |connection, connection_name|
  MySharedModel.select_all_data...
end
```

As such, migrations modifying data of `gitlab_shared` tables are expected to run across
all decomposed databases.

### The special purpose of `gitlab_internal`

`gitlab_internal` describes Rails-defined tables (like `schema_migrations` or `ar_internal_metadata`), as well as internal PostgreSQL tables (for example, `pg_attribute`). Its primary purpose is to [support other databases](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/85842#note_943453682), like Geo, that
might be missing some of those application-defined `gitlab_shared` tables (like `loose_foreign_keys_deleted_records`), but are valid Rails databases.

### The special purpose of `gitlab_pm`

`gitlab_pm` stores package metadata describing public repositories. This data is used for the License Compliance and Dependency Scanning product categories and is maintained by the [Composition Analysis Group](https://handbook.gitlab.com/handbook/engineering/development/sec/secure/composition-analysis/). It is an alias for `gitlab_main` intended to make it easier to route to a different database in the future.

## Migrations

Read [Migrations for Multiple Databases](migrations_for_multiple_databases.md).

## CI/CD Database

### Configure single database

By default, GDK is configured to run with multiple databases.

WARNING:
Switching back-and-forth between single and multiple databases in
the same development instance is discouraged. Any data in the `ci`
database will not be accessible in single database mode. For single database, you should use a separate development instance.

To configure GDK to use a single database:

1. On the GDK root directory, run:

   ```shell
   gdk config set gitlab.rails.databases.ci.enabled false
   ```

1. Reconfigure GDK:

   ```shell
   gdk reconfigure
   ```

To switch back to using multiple databases, set `gitlab.rails.databases.ci.enabled` to `true` and run `gdk reconfigure`.

<!--
NOTE: The `validate_cross_joins!` method in `spec/support/database/prevent_cross_joins.rb` references
      the following heading in the code, so if you make a change to this heading, make sure to update
      the corresponding documentation URL used in `spec/support/database/prevent_cross_joins.rb`.
-->

### Removing joins between `ci` and non `ci` tables

Queries that join across databases raise an error. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/68620)
in GitLab 14.3, for new queries only. Pre-existing queries do not raise an error.

Because GitLab can be run with multiple separate databases, referencing `ci`
tables with non `ci` tables in a single query is not possible. Therefore,
using any kind of `JOIN` in SQL queries will not work.

#### Suggestions for removing cross-database joins

The following sections are some real examples that were identified as joining across databases,
along with possible suggestions on how to fix them.

##### Remove the code

The simplest solution we've seen several times now has been an existing scope
that is unused. This is the easiest example to fix. So the first step is to
investigate if the code is unused and then remove it. These are some
real examples:

- <https://gitlab.com/gitlab-org/gitlab/-/merge_requests/67162>
- <https://gitlab.com/gitlab-org/gitlab/-/merge_requests/66714>
- <https://gitlab.com/gitlab-org/gitlab/-/merge_requests/66503>

There may be more examples where the code is used, but we can evaluate
if we need it or if the feature should behave this way.
Before complicating things by adding new columns and tables,
consider if you can simplify the solution and still meet the requirements.
One case being evaluated involves changing how certain `UsageData` is
calculated to remove a join query in
<https://gitlab.com/gitlab-org/gitlab/-/issues/336170>. This is a good candidate
to evaluate, because `UsageData` is not critical to users and it may be possible
to get a similarly useful metric with a simpler approach. Alternatively we may
find that nobody is using these metrics, so we can remove them.

##### Use `preload` instead of `includes`

The `includes` and `preload` methods in Rails are both ways to avoid an N+1
query. The `includes` method in Rails uses a heuristic approach to determine
if it needs to join to the table, or if it can load all of the
records in a separate query. This method assumes it needs to join if it thinks
you need to query the columns from the other table, but sometimes
this method gets it wrong and executes a join even when not needed. In
this case using `preload` to explicitly load the data in a separate query
allows you to avoid the join, while still avoiding the N+1 query.

You can see a real example of this solution being used in
<https://gitlab.com/gitlab-org/gitlab/-/merge_requests/67655>.

##### Remove a redundant join

Sometimes there are cases where a query is doing excess (or redundant) joins.

A common example occurs where a query is joining from `A` to `C`, via some
table with both foreign keys, `B`.
When you only care about counting how
many rows there are in `C` and if there are foreign keys and `NOT NULL` constraints
on the foreign keys in `B`, then it might be enough to count those rows.
For example, in
[MR 71811](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/71811), it was
previously doing `project.runners.count`, which would produce a query like:

```sql
select count(*) from projects
inner join ci_runner_projects on ci_runner_projects.project_id = projects.id
where ci_runner_projects.runner_id IN (1, 2, 3)
```

This was changed to avoid the cross-join by changing the code to
`project.runner_projects.count`. It produces the same response with the
following query:

```sql
select count(*) from ci_runner_projects
where ci_runner_projects.runner_id IN (1, 2, 3)
```

Another common redundant join is joining all the way to another table,
then filtering by primary key when you could have instead filtered on a foreign
key. See an example in
[MR 71614](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/71614). The previous
code was `joins(scan: :build).where(ci_builds: { id: build_ids })`, which
generated a query like:

```sql
select ...
inner join security_scans
inner join ci_builds on security_scans.build_id = ci_builds.id
where ci_builds.id IN (1, 2, 3)
```

However, as `security_scans` already has a foreign key `build_id`, the code
can be changed to `joins(:scan).where(security_scans: { build_id: build_ids })`,
which produces the same response with the following query:

```sql
select ...
inner join security_scans
where security_scans.build_id IN (1, 2, 3)
```

Both of these examples of removing redundant joins remove the cross-joins,
but they have the added benefit of producing simpler and faster
queries.

##### Limited pluck followed by a find

Using `pluck` or `pick` to get an array of `id`s is not advisable unless the returned
array is guaranteed to be bounded in size. Usually this is a good pattern where
you know the result will be at most 1, or in cases where you have a list of in
memory ids (or usernames) that need to be mapped to another list of equal size.
It would not be suitable when mapping a list of ids in a one-to-many
relationship as the result will be unbounded. We can then use the
returned `id`s to obtain the related record:

```ruby
allowed_user_id = board_user_finder
  .where(user_id: params['assignee_id'])
  .pick(:user_id)

User.find_by(id: allowed_user_id)
```

You can see an example where this was used in
<https://gitlab.com/gitlab-org/gitlab/-/merge_requests/126856>

Sometimes it might seem easy to convert a join into a `pluck` but often this
results in loading an unbounded amount of ids into memory and then
re-serializing those in a following query back to Postgres. These cases do not
scale and we recommend attempting one of the other options. It might seem like a
good idea to just apply some `limit` to the plucked data to have bounded memory
but this introduces unpredictable results for users and often is most
problematic for our largest customers (including ourselves), and as such we
advise against it.

##### De-normalize some foreign key to the table

De-normalization refers to adding redundant precomputed (duplicated) data to
a table to simplify certain queries or to improve performance. In this
case, it can be useful when you are doing a join that involves three tables, where
you are joining through some intermediate table.

Generally when modeling a database schema, a "normalized" structure is
preferred because of the following reasons:

- Duplicate data uses extra storage.
- Duplicate data needs to be kept in sync.

Sometimes normalized data is less performant so de-normalization has been a
common technique GitLab has used to improve the performance of database queries
for a while. The above problems are mitigated when the following conditions are
met:

1. There isn't much data (for example, it's just an integer column).
1. The data does not update often (for example, the `project_id` column is almost
   never updated for most tables).

One example we found was the `security_scans` table. This table has a foreign
key `security_scans.build_id` which allows you to join to the build. Therefore
you could join to the project like so:

```sql
select projects.* from security_scans
inner join ci_builds on security_scans.build_id = ci_builds.id
inner join projects on ci_builds.project_id = projects.id
```

The problem with this query is that `ci_builds` is in a different database
from the other two tables.

The solution in this case is to add the `project_id` column to
`security_scans`. This doesn't use much extra storage, and due to the way
these features work, it's never updated (a build never moves projects).

This simplified the query to:

```sql
select projects.* from security_scans
inner join projects on security_scans.project_id = projects.id
```

This also improves performance because you don't need to join through an extra
table.

You can see this approach implemented in
<https://gitlab.com/gitlab-org/gitlab/-/merge_requests/66963> . This MR also
de-normalizes `pipeline_id` to fix a similar query.

##### De-normalize into an extra table

Sometimes the previous de-normalization (adding an extra column) doesn't work for
your specific case. This may be due to the fact that your data is not 1:1, or
because the table you're adding to is already too wide (for example, the `projects`
table shouldn't have more columns added).

In this case you may decide to just store the extra data in a separate table.

One example where this approach is being used was to implement the
`Project.with_code_coverage` scope. This scope was essentially used to narrow
down a list of projects to only those that have at one point in time used code
coverage features. This query (simplified) was:

```sql
select projects.* from projects
inner join ci_daily_build_group_report_results on ci_daily_build_group_report_results.project_id = projects.id
where ((data->'coverage') is not null)
and ci_daily_build_group_report_results.default_branch = true
group by projects.id
```

This work is still in progress but the current plan is to introduce a new table
called `projects_with_ci_feature_usage` which has 2 columns `project_id` and
`ci_feature`. This table would be written to the first time a project creates a
`ci_daily_build_group_report_results` for code coverage. Therefore the new
query would be:

```sql
select projects.* from projects
inner join projects_with_ci_feature_usage on projects_with_ci_feature_usage.project_id = projects.id
where projects_with_ci_feature_usage.ci_feature = 'code_coverage'
```

The above example uses as a text column for simplicity but we should probably
use an [enum](creating_enums.md) to save space.

The downside of this new design is that this may need to be
updated (removed if the `ci_daily_build_group_report_results` is deleted).
Depending on your domain, however, this may not be necessary because deletes are
edge cases or impossible, or because the user impact of seeing the project on the
list page may not be problematic. It's also possible to implement the
logic to delete these rows if or whenever necessary in your domain.

Finally, this de-normalization and new query also improves performance because
it does less joins and needs less filtering.

##### Use `disable_joins` for `has_one` or `has_many` `through:` relations

Sometimes a join query is caused by using `has_one ... through:` or `has_many ... through:`
across tables that span the different databases. These joins
sometimes can be solved by adding
[`disable_joins:true`](https://edgeguides.rubyonrails.org/active_record_multiple_databases.html#handling-associations-with-joins-across-databases).
This is a Rails feature which we
[backported](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/66400). We
also extended the feature to allow a lambda syntax for enabling `disable_joins`
with a feature flag. If you use this feature we encourage using a feature flag
as it mitigates risk if there is some serious performance regression.

You can see an example where this was used in
<https://gitlab.com/gitlab-org/gitlab/-/merge_requests/66709/diffs>.

With any change to DB queries it is important to analyze and compare the SQL
before and after the change. `disable_joins` can introduce very poorly performing
code depending on the actual logic of the `has_many` or `has_one` relationship.
The key thing to look for is whether any of the intermediate result sets
used to construct the final result set have an unbounded amount of data loaded.
The best way to tell is by looking at the SQL generated and confirming that
each one is limited in some way. You can tell by either a `LIMIT 1` clause or
by `WHERE` clause that is limiting based on a unique column. Any unbounded
intermediate dataset could lead to loading too many IDs into memory.

An example where you may see very poor performance is the following
hypothetical code:

```ruby
class Project
  has_many :pipelines
  has_many :builds, through: :pipelines
end

class Pipeline
  has_many :builds
end

class Build
  belongs_to :pipeline
end

def some_action
  @builds = Project.find(5).builds.order(created_at: :desc).limit(10)
end
```

In the above case `some_action` will generate a query like:

```sql
select * from builds
inner join pipelines on builds.pipeline_id = pipelines.id
where pipelines.project_id = 5
order by builds.created_at desc
limit 10
```

However, if you changed the relation to be:

```ruby
class Project
  has_many :pipelines
  has_many :builds, through: :pipelines, disable_joins: true
end
```

Then you would get the following 2 queries:

```sql
select id from pipelines where project_id = 5;

select * from builds where pipeline_id in (...)
order by created_at desc
limit 10;
```

Because the first query does not limit by any unique column or
have a `LIMIT` clause, it can load an unlimited number of
pipeline IDs into memory, which are then sent in the following query.
This can lead to very poor performance in the Rails application and the
database. In cases like this, you might need to re-write the
query or look at other patterns described above for removing cross-joins.

#### How to validate you have correctly removed a cross-join

RSpec is configured to automatically validate all SQL queries do not join
across databases. If this validation is disabled in
`spec/support/database/cross-join-allowlist.yml` then you can still validate an
isolated code block using `with_cross_joins_prevented`.

You can use this method like so:

```ruby
it 'does not join across databases' do
  with_cross_joins_prevented do
    ::Ci::Build.joins(:project).to_a
  end
end
```

This will raise an exception if the query joins across the two databases. The
previous example is fixed by removing the join, like so:

```ruby
it 'does not join across databases' do
  with_cross_joins_prevented do
    ::Ci::Build.preload(:project).to_a
  end
end
```

You can see a real example of using this method for fixing a cross-join in
<https://gitlab.com/gitlab-org/gitlab/-/merge_requests/67655>.

#### Allowlist for existing cross-joins

The easiest way of identifying a cross-join is via failing pipelines.

As an example, in [!130038](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/130038/diffs) we moved the `notification_settings` table to the `gitlab_main_cell` schema, by marking it as such in the `db/docs/notification_settings.yml` file.

The pipeline failed with the following [error](https://gitlab.com/gitlab-org/gitlab/-/jobs/4929130983):

```ruby
Database::PreventCrossJoins::CrossJoinAcrossUnsupportedTablesError:

Unsupported cross-join across 'users, notification_settings' querying 'gitlab_main_clusterwide, gitlab_main_cell' discovered when executing query 'SELECT "users".* FROM "users" WHERE "users"."id" IN (SELECT "notification_settings"."user_id" FROM ((SELECT "notification_settings"."user_id" FROM "notification_settings" WHERE "notification_settings"."source_id" = 119 AND "notification_settings"."source_type" = 'Project' AND (("notification_settings"."level" = 3 AND EXISTS (SELECT true FROM "notification_settings" "notification_settings_2" WHERE "notification_settings_2"."user_id" = "notification_settings"."user_id" AND "notification_settings_2"."source_id" IS NULL AND "notification_settings_2"."source_type" IS NULL AND "notification_settings_2"."level" = 2)) OR "notification_settings"."level" = 2))) notification_settings)'
```

To make the pipeline green, this cross-join query must be allow-listed.

A cross-join across databases can be explicitly allowed by wrapping the code in the
`::Gitlab::Database.allow_cross_joins_across_databases` helper method. Alternative
way is to mark a given relation as `relation.allow_cross_joins_across_databases`.

This method should only be used:

- For existing code.
- If the code is required to help migrate away from a cross-join. For example,
  in a migration that backfills data for future use to remove a cross-join.

The `allow_cross_joins_across_databases` helper method can be used as follows:

```ruby
# Scope the block executing a object from database
::Gitlab::Database.allow_cross_joins_across_databases(url: 'https://gitlab.com/gitlab-org/gitlab/-/issues/336590') do
  subject.perform(1, 4)
end
```

```ruby
# Mark a relation as allowed to cross-join databases
def find_diff_head_pipeline
  all_pipelines
    .allow_cross_joins_across_databases(url: 'https://gitlab.com/gitlab-org/gitlab/-/issues/336891')
    .for_sha_or_source_sha(diff_head_sha)
    .first
end
```

In model associations or scopes, this can be used as in the following example:

```ruby
class Group < Namespace
 has_many :users, -> {
    allow_cross_joins_across_databases(url: "https://gitlab.com/gitlab-org/gitlab/-/issues/422405")
  }, through: :group_members
end
```

WARNING:
Overriding an association can have unintended consequences and may even lead to data loss, as we noticed in [issue 424307](https://gitlab.com/gitlab-org/gitlab/-/issues/424307). Do not override existing ActiveRecord associations to mark a cross-join as allowed, as in the example below.

```ruby
class Group < Namespace
  has_many :users, through: :group_members

  # DO NOT override an association like this.
  def users
    super.allow_cross_joins_across_databases(url: "https://gitlab.com/gitlab-org/gitlab/-/issues/422405")
  end
end
```

The `url` parameter should point to an issue with a milestone for when we intend
to fix the cross-join. If the cross-join is being used in a migration, we do not
need to fix the code. See <https://gitlab.com/gitlab-org/gitlab/-/issues/340017>
for more details.

### Removing cross-database transactions

When dealing with multiple databases, it's important to pay close attention to data modification
that affects more than one database.
[Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/339811) GitLab 14.4, an automated check
prevents cross-database modifications.

When at least two different databases are modified during a transaction initiated on any database
server, the application triggers a cross-database modification error (only in test environment).

Example:

```ruby
# Open transaction on Main DB
ApplicationRecord.transaction do
  ci_build.update!(updated_at: Time.current) # UPDATE on CI DB
  ci_build.project.update!(updated_at: Time.current) # UPDATE on Main DB
end
# raises error: Cross-database data modification of 'main, ci' were detected within
# a transaction modifying the 'ci_build, projects' tables
```

The code example above updates the timestamp for two records within a transaction. With the
ongoing work on the CI database decomposition, we cannot ensure the schematics of a database
transaction.
If the second update query fails, the first update query will not be
rolled back because the `ci_build` record is located on a different database server. For
more information, look at the
[transaction guidelines](transaction_guidelines.md#dangerous-example-third-party-api-calls)
page.

#### Fixing cross-database transactions

A transaction across databases can be explicitly allowed by wrapping the code in the
`Gitlab::Database::QueryAnalyzers::PreventCrossDatabaseModification.temporary_ignore_tables_in_transaction` helper method.

For cross-database transactions in Rails callbacks, the `cross_database_ignore_tables` method can be used.

These methods should only be used for existing code.

The `temporary_ignore_tables_in_transaction` helper method can be used as follows:

```ruby
class GroupMember < Member
   def update_two_factor_requirement
     return unless user

     # To mark and ignore cross-database transactions involving members and users/user_details/user_preferences
     Gitlab::Database::QueryAnalyzers::PreventCrossDatabaseModification.temporary_ignore_tables_in_transaction(
       %w[users user_details user_preferences], url: 'https://gitlab.com/gitlab-org/gitlab/-/issues/424288'
     ) do
       user.update_two_factor_requirement
     end
   end
end
```

The `cross_database_ignore_tables` method can be used as follows:

```ruby
class Namespace < ApplicationRecord
  include CrossDatabaseIgnoredTables

  # To mark and ignore cross-database transactions involving namespaces and routes/redirect_routes happening within Rails callbacks.
  cross_database_ignore_tables %w[routes redirect_routes], url: 'https://gitlab.com/gitlab-org/gitlab/-/issues/424277'
end
```

##### Removing the transaction block

Without an open transaction, the cross-database modification check cannot raise an error.
By making this change, we sacrifice consistency. In case of an application failure after the
first `UPDATE` query, the second `UPDATE` query will never execute.

The same code without the `transaction` block:

```ruby
ci_build.update!(updated_at: Time.current) # CI DB
ci_build.project.update!(updated_at: Time.current) # Main DB
```

##### Asynchronous processing

If we need more guarantee that an operation finishes the work consistently we can execute it
within a background job. A background job is scheduled asynchronously and retried several times
in case of an error. There is still a very small chance of introducing inconsistency.

Example:

```ruby
current_time = Time.current

MyAsyncConsistencyJob.perform_async(cu_build.id)

ci_build.update!(updated_at: current_time)
ci_build.project.update!(updated_at: current_time)
```

The `MyAsyncConsistencyJob` would also attempt to update the timestamp if they differ.

##### Aiming for perfect consistency

At this point, we don't have the tooling (we might not even need it) to ensure similar consistency
characteristics as we had with one database. If you think that the code you're working on requires
these properties, then you can disable the cross-database modification check in your tests by wrapping the
offending test code with a block and create a follow-up issue.

```ruby
allow_cross_database_modification_within_transaction(url: 'gitlab issue URL') do
  ApplicationRecord.transaction do
    ci_build.update!(updated_at: Time.current) # UPDATE on CI DB
    ci_build.project.update!(updated_at: Time.current) # UPDATE on Main DB
  end
end
```

Don't hesitate to reach out to the
[Pods group](https://handbook.gitlab.com/handbook/engineering/infrastructure/core-platform/data_stores/tenant-scale/)
for advice.

##### Avoid `dependent: :nullify` and `dependent: :destroy` across databases

There may be cases where we want to use `dependent: :nullify` or `dependent: :destroy`
across databases. This is technically possible, but it's problematic because
these hooks run in the context of an outer transaction from the call to
`#destroy`, which creates a cross-database transaction and we are trying to
avoid that. Cross-database transactions caused this way could lead to confusing
outcomes when we switch to decomposed, because now you have some queries
happening outside the transaction and they may be partially applied while the
outer transaction fails, which could lead to surprising bugs.

For non-trivial objects that need to clean up data outside the
database (for example, object storage), we recommend the setting
[`dependent: :restrict_with_error`](https://guides.rubyonrails.org/association_basics.html#options-for-has-one-dependent).
Such objects should be removed explicitly ahead of time. Using `dependent: :restrict_with_error`
ensures that we forbid destroying the parent object if something is not cleaned up.

If all you need to do is clean up the child records themselves from PostgreSQL,
consider using [loose foreign keys](loose_foreign_keys.md).

## Foreign keys that cross databases

There are many places where we use foreign keys that reference across the two
databases. This is not possible to do with two separate PostgreSQL
databases, so we need to replicate the behavior we get from PostgreSQL in a
performant way. We can't, and shouldn't, try to replicate the data guarantees
given by PostgreSQL which prevent creating invalid references, but we still need a
way to replace cascading deletes so we don't end up with orphaned data
or records that point to nowhere, which might lead to bugs. As such we created
["loose foreign keys"](loose_foreign_keys.md) which is an asynchronous
process of cleaning up orphaned records.

### Allowlist for existing cross-database foreign keys

The easiest way of identifying a cross-database foreign key is via failing pipelines.

As an example, in [!130038](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/130038/diffs) we moved the `notification_settings` table to the `gitlab_main_cell` schema, by marking it in the `db/docs/notification_settings.yml` file.

`notification_settings.user_id` is a column that points to `users`, but the `users` table belongs to a different database, thus this is now treated as a cross-database foreign key.

We have a spec to capture such cases of cross-database foreign keys in [`no_cross_db_foreign_keys_spec.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/01d3a1e41513200368a22bbab5d4312174762ee0/spec/lib/gitlab/database/no_cross_db_foreign_keys_spec.rb), which would fail if such a cross-database foreign key is encountered.

To make the pipeline green, this cross-database foreign key must be allow-listed.

To do this, explicitly allow the existing cross-database foreign key to exist by adding it as an exception in the same spec (as in [this example](https://gitlab.com/gitlab-org/gitlab/-/blob/7d99387f399c548af24d93d564b35f2f9510662d/spec/lib/gitlab/database/no_cross_db_foreign_keys_spec.rb#L26)).
This way, the spec will not fail.

Later, this foreign key can be converted to a loose foreign key, like we did in [!130080](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/130080/diffs).

## Testing for multiple databases

In our testing CI pipelines, we test GitLab by default with multiple databases set up, using
both `main` and `ci` databases. But in merge requests, for example when we modify some database-related code or
add the label `~"pipeline:run-single-db"` to the MR, we additionally run our tests in
[two other database modes](../pipelines/_index.md#single-database-testing):
`single-db` and `single-db-ci-connection`.

To handle situations where our tests need to run in specific database modes, we have some RSpec helpers
to limit the modes where tests can run, and skip them on any other modes.

| Helper name                                 | Test runs |
|---------------------------------------------| ---      |
| `skip_if_shared_database(:ci)`              | On **multiple databases**   |
| `skip_if_database_exists(:ci)`              | On **single-db** and **single-db-ci-connection**   |
| `skip_if_multiple_databases_are_setup(:ci)` | Only on **single-db**   |
| `skip_if_multiple_databases_not_setup(:ci)` | On **single-db-ci-connection** and **multiple databases** |

## Locking writes on the tables that don't belong to the database schemas

When the CI database is promoted and the two databases are fully split,
as an extra safeguard against creating a split brain situation,
run the Rake task `gitlab:db:lock_writes`. This command locks writes on:

- The `gitlab_main` tables on the CI Database.
- The `gitlab_ci` tables on the Main Database.

This Rake task adds triggers to all the tables, to prevent any
`INSERT`, `UPDATE`, `DELETE`, or `TRUNCATE` statements from running
against the tables that need to be locked.

If this task was run against a GitLab setup that uses only a single database
for both `gitlab_main` and `gitlab_ci` tables, then no tables will be locked.

To undo the operation, run the opposite Rake task: `gitlab:db:unlock_writes`.

### Monitoring

The status of the table locks is checked using the
[`Database::MonitorLockedTablesWorker`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/workers/database/monitor_locked_tables_worker.rb).
It will lock tables if needed.

The result of this script is available in [Kibana](https://log.gprd.gitlab.net/app/r/s/4qrz2).
If the counts are not 0, there are some tables that should have been locked but are not.
The fields `json.extra.database_monitor_locked_tables_worker.results.ci.tables_need_locks` and
`json.extra.database_monitor_locked_tables_worker.results.main.tables_need_locks` should contain
a list of tables that have the wrong state.

The logging is monitored using a [Elasticsearch Watcher](https://log.gprd.gitlab.net/app/management/insightsAndAlerting/watcher/watches).
The watcher is called `table_locks_needed` and the source code is in the
[GitLab Runbook repository](https://gitlab.com/gitlab-com/runbooks/-/tree/master/elastic/managed-objects/log_gprd/watches).
The alerts are sent to [#g_tenant-scale](https://gitlab.enterprise.slack.com/archives/C01TQ838Y3T) Slack channel.

### Automation

There are two processes that automatically lock tables:

- Database migrations. See [`Gitlab::Database::MigrationHelpers::AutomaticLockWritesOnTables`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/database/migration_helpers/automatic_lock_writes_on_tables.rb)
- The `Database::MonitorLockedTablesWorker` locks tables if needed.
  This can be disabled by the `lock_tables_in_monitoring` feature flag.

### Manually lock tables

If you need to manually lock a table, use a database migration.
Create a regular migration and add the code for locking the table.
For example, set a write lock on `shards` table in CI database:

```ruby
class EnableWriteLocksOnShards < Gitlab::Database::Migration[2.2]
  def up
    # On main database, the migration should be skipped
    # We can't use restrict_gitlab_migration in DDL migrations
    return if Gitlab::Database.db_config_name(connection) != 'ci'

    Gitlab::Database::LockWritesManager.new(
      table_name: 'shards',
      connection: connection,
      database_name: :ci,
      with_retries: false
    ).lock_writes
  end

  def down
    # no-op
  end
end
```

## Truncating tables

When the databases `main` and `ci` are fully split, we can free up disk
space by truncating tables. This results in a smaller data set: For example,
the data in `users` table on CI database is no longer read and also no
longer updated. So this data can be removed by truncating the tables.

For this purpose, GitLab provides two Rake tasks, one for each database:

- `gitlab:db:truncate_legacy_tables:main` will truncate the CI tables in Main database.
- `gitlab:db:truncate_legacy_tables:ci` will truncate the Main tables in CI database.

NOTE:
These tasks can only be run when the tables in the database are
[locked for writes](#locking-writes-on-the-tables-that-dont-belong-to-the-database-schemas).

WARNING:
The examples in this section use `DRY_RUN=true`. This ensures no data is actually
truncated. GitLab highly recommends to have a backup available before you run any of
these tasks without `DRY_RUN=true`.

These tasks have the option to see what they do without actually changing the
data:

```shell
$ sudo DRY_RUN=true gitlab-rake gitlab:db:truncate_legacy_tables:main
I, [2023-07-14T17:08:06.665151 #92505]  INFO -- : DRY RUN:
I, [2023-07-14T17:08:06.761586 #92505]  INFO -- : Truncating legacy tables for the database main
I, [2023-07-14T17:08:06.761709 #92505]  INFO -- : SELECT set_config('lock_writes.ci_build_needs', 'false', false)
I, [2023-07-14T17:08:06.765272 #92505]  INFO -- : SELECT set_config('lock_writes.ci_build_pending_states', 'false', false)
I, [2023-07-14T17:08:06.768220 #92505]  INFO -- : SELECT set_config('lock_writes.ci_build_report_results', 'false', false)
[...]
I, [2023-07-14T17:08:06.957294 #92505]  INFO -- : TRUNCATE TABLE ci_build_needs, ci_build_pending_states, ci_build_report_results, ci_build_trace_chunks, ci_build_trace_metadata, ci_builds, ci_builds_metadata, ci_builds_runner_session, ci_cost_settings, ci_daily_build_group_report_results, ci_deleted_objects, ci_freeze_periods, ci_group_variables, ci_instance_variables, ci_job_artifact_states, ci_job_artifacts, ci_job_token_project_scope_links, ci_job_variables, ci_minutes_additional_packs, ci_namespace_mirrors, ci_namespace_monthly_usages, ci_partitions, ci_pending_builds, ci_pipeline_artifacts, ci_pipeline_chat_data, ci_pipeline_messages, ci_pipeline_metadata, ci_pipeline_schedule_variables, ci_pipeline_schedules, ci_pipeline_variables, ci_pipelines, ci_pipelines_config, ci_platform_metrics, ci_project_mirrors, ci_project_monthly_usages, ci_refs, ci_resource_groups, ci_resources, ci_runner_machines, ci_runner_namespaces, ci_runner_projects, ci_runner_versions, ci_runners, ci_running_builds, ci_secure_file_states, ci_secure_files, ci_sources_pipelines, ci_sources_projects, ci_stages, ci_subscriptions_projects, ci_trigger_requests, ci_triggers, ci_unit_test_failures, ci_unit_tests, ci_variables, external_pull_requests, p_ci_builds, p_ci_builds_metadata, p_ci_job_annotations, p_ci_runner_machine_builds, taggings, tags RESTRICT
```

The tasks will first find out the tables that need to be truncated. Truncation will
happen in stages because we need to limit the amount of data removed in one database
transaction. The tables are processed in a specific order depending on the definition
of the foreign keys. The number of tables processed in one stage can be changed by
adding a number when invoking the task. The default value is 5:

```shell
sudo DRY_RUN=true gitlab-rake gitlab:db:truncate_legacy_tables:main\[10\]
```

It is also possible to limit the number of tables to be truncated by setting the `UNTIL_TABLE`
variable. For example in this case, the process will stop when `ci_unit_test_failures` has been
truncated:

```shell
sudo DRY_RUN=true UNTIL_TABLE=ci_unit_test_failures gitlab-rake gitlab:db:truncate_legacy_tables:main
```
