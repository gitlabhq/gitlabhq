---
stage: Enablement
group: Sharding
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Multiple Databases

To scale GitLab, the we are
[decomposing the GitLab application database into multiple databases](https://gitlab.com/groups/gitlab-org/-/epics/6168).

## CI/CD Database

> Support for configuring the GitLab Rails application to use a distinct
database for CI/CD tables was [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/64289)
in GitLab 14.1. This feature is still under development, and is not ready for production use.

### Development setup

By default, GitLab is configured to use only one main database. To
opt-in to use a main database, and CI database, modify the
`config/database.yml` file to have a `main` and a `ci` database
configurations.

You can set this up using [GDK](#gdk-configuration) or by
[manually configuring `config/database.yml`](#manually-set-up-the-cicd-database).

#### GDK configuration

If you are using GDK, you can follow the following steps:

1. On the GDK root directory, run:

   ```shell
   gdk config set gitlab.rails.multiple_databases true
   ```

1. Open your `gdk.yml`, and confirm that it has the following lines:

   ```yaml
   gitlab:
     rails:
       databases:
         ci:
           enabled: true
   ```

1. Reconfigure GDK:

   ```shell
   gdk reconfigure
   ```

1. [Create the new CI/CD database](#create-the-new-database).

#### Manually set up the CI/CD database

You can manually edit `config/database.yml` to split the databases.
To do so, consider a `config/database.yml` file like the example below:

```yaml
development:
  main:
    adapter: postgresql
    encoding: unicode
    database: gitlabhq_development
    host: /path/to/gdk/postgresql
    pool: 10
    prepared_statements: false
    variables:
      statement_timeout: 120s

test: &test
  main:
    adapter: postgresql
    encoding: unicode
    database: gitlabhq_test
    host: /path/to/gdk/postgresql
    pool: 10
    prepared_statements: false
    variables:
      statement_timeout: 120s
```

Edit it to split the databases into `main` and `ci`:

```yaml
development:
  main:
    adapter: postgresql
    encoding: unicode
    database: gitlabhq_development
    host: /path/to/gdk/postgresql
    pool: 10
    prepared_statements: false
    variables:
      statement_timeout: 120s
  ci:
    adapter: postgresql
    encoding: unicode
    database: gitlabhq_development_ci
    host: /path/to/gdk/postgresql
    pool: 10
    prepared_statements: false
    variables:
      statement_timeout: 120s

test: &test
  main:
    adapter: postgresql
    encoding: unicode
    database: gitlabhq_test
    host: /path/to/gdk/postgresql
    pool: 10
    prepared_statements: false
    variables:
      statement_timeout: 120s
  ci:
    adapter: postgresql
    encoding: unicode
    database: gitlabhq_test_ci
    host: /path/to/gdk/postgresql
    pool: 10
    prepared_statements: false
    variables:
      statement_timeout: 120s
```

Next, [create the new CI/CD database](#create-the-new-database).

#### Create the new database

After configuring GitLab for the two databases, create the new CI/CD database:

1. Create the new `ci:` database, load the DB schema into the `ci:` database,
   and run any pending migrations:

    ```shell
    bundle exec rails db:create db:schema:load:ci db:migrate
    ```

1. Restart GDK:

    ```shell
    gdk restart
    ```

<!--
NOTE: The `validate_cross_joins!` method in `spec/support/database/prevent_cross_joins.rb` references
      the following heading in the code, so if you make a change to this heading, make sure to update
      the corresponding documentation URL used in `spec/support/database/prevent_cross_joins.rb`.
-->

### Removing joins between `ci_*` and non `ci_*` tables

Queries that join across databases raise an error. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/68620)
in GitLab 14.3, for new queries only. Pre-existing queries do not raise an error.

We are planning on moving all the `ci_*` tables to a separate database, so
referencing `ci_*` tables with other tables will not be possible. This means,
that using any kind of `JOIN` in SQL queries will not work. We have identified
already many such examples that need to be fixed in
<https://gitlab.com/groups/gitlab-org/-/epics/6289> .

#### Path to removing cross-database joins

The following steps are the process to remove cross-database joins between
`ci_*` and non `ci_*` tables:

1. **{check-circle}** Add all failing specs to the [`cross-join-allowlist.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/f5de89daeb468fc45e1e95a76d1b5297aa53da11/spec/support/database/cross-join-allowlist.yml)
   file.
1. **{dotted-circle}** Find the code that caused the spec failure and wrap the isolated code
   in [`allow_cross_joins_across_databases`](#allowlist-for-existing-cross-joins).
   Link to a new issue assigned to the correct team to remove the specs from the
   `cross-join-allowlist.yml` file.
1. **{dotted-circle}** Remove the `cross-join-allowlist.yml` file and stop allowing
   whole test files.
1. **{dotted-circle}** Fix the problem and remove the `allow_cross_joins_across_databases` call.
1. **{dotted-circle}** Fix all the cross-joins and remove the `allow_cross_joins_across_databases` method.

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
use an [enum](../creating_enums.md) to save space.

The downside of this new design is that this may need to be
updated (removed if the `ci_daily_build_group_report_results` is deleted).
Depending on your domain, however, this may not be necessary because deletes are
edge cases or impossible, or because the user impact of seeing the project on the
list page may not be problematic. It's also possible to implement the
logic to delete these rows if or whenever necessary in your domain.

Finally, this de-normalization and new query also improves performance because
it does less joins and needs less filtering.

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

##### Use `disable_joins` for `has_one` or `has_many` `through:` relations

Sometimes a join query is caused by using `has_one ... through:` or `has_many
... through:` across tables that span the different databases. These joins
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

Using RSpec tests, you can validate all SQL queries within a code block to
ensure that none of them are joining across the two databases. This is a useful
tool to confirm you have correctly fixed an existing cross-join.

At some point in the future we will have fixed all cross-joins and this tool
will run by default in all tests. For now, the tool needs to be explicitly enabled
for your test.

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
def find_actual_head_pipeline
  all_pipelines
    .allow_cross_joins_across_databases(url: 'https://gitlab.com/gitlab-org/gitlab/-/issues/336891')
    .for_sha_or_source_sha(diff_head_sha)
    .first
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

#### Fixing cross-database errors

##### Removing the transaction block

Without an open transaction, the cross-database modification check cannot raise an error.
By making this change, we sacrifice consistency. In case of an application failure after the
first `UPDATE` query, the second `UPDATE` query will never execute.

The same code without the `transaction` block:

```ruby
ci_build.update!(updated_at: Time.current) # CI DB
ci_build.project.update!(updated_at: Time.current) # Main DB
```

##### Async processing

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
these properties, then you can disable the cross-database modification check by wrapping to
offending database queries with a block and create a follow-up issue mentioning the sharding group
(`gitlab-org/sharding-group`).

```ruby
Gitlab::Database.allow_cross_joins_across_databases(url: 'gitlab issue URL') do
  ApplicationRecord.transaction do
    ci_build.update!(updated_at: Time.current) # UPDATE on CI DB
    ci_build.project.update!(updated_at: Time.current) # UPDATE on Main DB
  end
end
```

Don't hesitate to reach out to the
[sharding group](https://about.gitlab.com/handbook/engineering/development/enablement/sharding/)
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

## `config/database.yml`

GitLab is adding support to run multiple databases, for example to
[separate tables for the continuous integration features](https://gitlab.com/groups/gitlab-org/-/epics/6167)
from the main database. In order to prepare for this change, we
[validate the structure of the configuration](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/67877)
in `database.yml` to ensure that only known databases are used.

Previously, the `config/database.yml` looked like this:

```yaml
production:
  adapter: postgresql
  encoding: unicode
  database: gitlabhq_production
  ...
```

With the support for many databases this
syntax is [deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/338182)
and will be removed in [15.0](https://gitlab.com/gitlab-org/gitlab/-/issues/338182).

The new `config/database.yml` needs to include a database name
to define a database configuration. Only `main:` and `ci:` database
names are supported. The `main:` database must always be a first
entry in a hash. This change applies to decomposed and non-decomposed
change. If an invalid or deprecated syntax is used the error
or warning is printed during application start.

```yaml
# Non-decomposed database
production:
  main:
    adapter: postgresql
    encoding: unicode
    database: gitlabhq_production
    ...

# Decomposed database
production:
  main:
    adapter: postgresql
    encoding: unicode
    database: gitlabhq_production
    ...
  ci:
    adapter: postgresql
    encoding: unicode
    database: gitlabhq_production_ci
    ...
```

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
