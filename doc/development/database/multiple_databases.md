---
stage: Enablement
group: Sharding
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Multiple Databases

In order to scale GitLab, the GitLab application database
will be [decomposed into multiple
databases](https://gitlab.com/groups/gitlab-org/-/epics/6168).

## CI Database

Support for configuring the GitLab Rails application to use a distinct
database for CI tables was added in [GitLab
14.1](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/64289). This
feature is still under development, and is not ready for production use.

By default, GitLab is configured to use only one main database. To
opt-in to use a main database, and CI database, modify the
`config/database.yml` file to have a `main` and a `ci` database
configurations. For example, given a `config/database.yml` like below:

```yaml
development:
  adapter: postgresql
  encoding: unicode
  database: gitlabhq_development
  host: /path/to/gdk/postgresql
  pool: 10
  prepared_statements: false
  variables:
    statement_timeout: 120s

test: &test
  adapter: postgresql
  encoding: unicode
  database: gitlabhq_test
  host: /path/to/gdk/postgresql
  pool: 10
  prepared_statements: false
  variables:
    statement_timeout: 120s
```

Edit the `config/database.yml` to look like this:

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

### Migrations

Any migrations that affect `Ci::CiDatabaseRecord` models
and their tables must be placed in two directories for now:

- `db/migrate`
- `db/ci_migrate`

We aim to keep the schema for both tables the same across both databases.

### Removing joins between `ci_*` and non `ci_*` tables

We are planning on moving all the `ci_*` tables to a separate database so
referencing `ci_*` tables with other tables will not be possible. This means,
that using any kind of `JOIN` in SQL queries will not work. We have identified
already many such examples that need to be fixed in
<https://gitlab.com/groups/gitlab-org/-/epics/6289> .

The following are some real examples that have resulted from this and these
patterns may apply to future cases.

#### Remove the code

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

#### Use `preload` instead of `includes`

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

#### De-normalize some foreign key to the table

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

#### De-normalize into an extra table

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

#### Summary of cross-join removal patterns

A quick checklist for fixing a specific join query would be:

1. Is the code even used? If not just remove it
1. If the code is used, then is this feature even used or can we implement the
   feature in a simpler way and still meet the requirements. Always prefer the
   simplest option.
1. Can we remove the join if we de-normalize the data you are joining to by
   adding a new column
1. Can we remove the join by adding a new table in the correct database that
   replicates the minimum data needed to do the join

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
