---
stage: Data Access
group: Database Frameworks
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: SQL Query Guidelines
---

This document describes various guidelines to follow when writing SQL queries,
either using ActiveRecord/Arel or raw SQL queries.

## Using `LIKE` Statements

The most common way to search for data is using the `LIKE` statement. For
example, to get all issues with a title starting with "Draft:" you'd write the
following query:

```sql
SELECT *
FROM issues
WHERE title LIKE 'Draft:%';
```

On PostgreSQL the `LIKE` statement is case-sensitive. To perform a case-insensitive
`LIKE` you have to use `ILIKE` instead.

To handle this automatically you should use `LIKE` queries using Arel instead
of raw SQL fragments, as Arel automatically uses `ILIKE` on PostgreSQL.

```ruby
Issue.where('title LIKE ?', 'Draft:%')
```

You'd write this instead:

```ruby
Issue.where(Issue.arel_table[:title].matches('Draft:%'))
```

Here `matches` generates the correct `LIKE` / `ILIKE` statement depending on the
database being used.

If you need to chain multiple `OR` conditions you can also do this using Arel:

```ruby
table = Issue.arel_table

Issue.where(table[:title].matches('Draft:%').or(table[:foo].matches('Draft:%')))
```

On PostgreSQL, this produces:

```sql
SELECT *
FROM issues
WHERE (title ILIKE 'Draft:%' OR foo ILIKE 'Draft:%')
```

## `LIKE` & Indexes

PostgreSQL does not use any indexes when using `LIKE` / `ILIKE` with a wildcard at
the start. For example, this does not use any indexes:

```sql
SELECT *
FROM issues
WHERE title ILIKE '%Draft:%';
```

Because the value for `ILIKE` starts with a wildcard the database is not able to
use an index as it doesn't know where to start scanning the indexes.

Luckily, PostgreSQL _does_ provide a solution: trigram Generalized Inverted Index (GIN) indexes. These
indexes can be created as follows:

```sql
CREATE INDEX [CONCURRENTLY] index_name_here
ON table_name
USING GIN(column_name gin_trgm_ops);
```

The key here is the `GIN(column_name gin_trgm_ops)` part. This creates a
[GIN index](https://www.postgresql.org/docs/current/gin.html)
with the operator class set to `gin_trgm_ops`. These indexes
_can_ be used by `ILIKE` / `LIKE` and can lead to greatly improved performance.
One downside of these indexes is that they can easily get quite large (depending
on the amount of data indexed).

To keep naming of these indexes consistent, use the following naming
pattern:

```plaintext
index_TABLE_on_COLUMN_trigram
```

For example, a GIN/trigram index for `issues.title` would be called
`index_issues_on_title_trigram`.

Due to these indexes taking quite some time to be built they should be built
concurrently. This can be done by using `CREATE INDEX CONCURRENTLY` instead of
just `CREATE INDEX`. Concurrent indexes can _not_ be created inside a
transaction. Transactions for migrations can be disabled using the following
pattern:

```ruby
class MigrationName < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!
end
```

For example:

```ruby
class AddUsersLowerUsernameEmailIndexes < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    execute 'CREATE INDEX CONCURRENTLY index_on_users_lower_username ON users (LOWER(username));'
    execute 'CREATE INDEX CONCURRENTLY index_on_users_lower_email ON users (LOWER(email));'
  end

  def down
    remove_index :users, :index_on_users_lower_username
    remove_index :users, :index_on_users_lower_email
  end
end
```

## Reliably referencing database columns

ActiveRecord by default returns all columns from the queried database table. In some cases the returned rows might need to be customized, for example:

- Specify only a few columns to reduce the amount of data returned from the database.
- Include columns from `JOIN` relations.
- Perform calculations (`SUM`, `COUNT`).

In this example we specify the columns, but not their tables:

- `path` from the `projects` table
- `user_id` from the `merge_requests` table

The query:

```ruby
# bad, avoid
Project.select("path, user_id").joins(:merge_requests) # SELECT path, user_id FROM "projects" ...
```

Later on, a new feature adds an extra column to the `projects` table: `user_id`. During deployment there might be a short time window where the database migration is already executed, but the new version of the application code is not deployed yet. When the query mentioned above executes during this period, the query fails with the following error message: `PG::AmbiguousColumn: ERROR: column reference "user_id" is ambiguous`

The problem is caused by the way the attributes are selected from the database. The `user_id` column is present in both the `users` and `merge_requests` tables. The query planner cannot decide which table to use when looking up the `user_id` column.

When writing a customized `SELECT` statement, it's better to **explicitly specify the columns with the table name**.

### Good (prefer)

```ruby
Project.select(:path, 'merge_requests.user_id').joins(:merge_requests)

# SELECT "projects"."path", merge_requests.user_id as user_id FROM "projects" ...
```

```ruby
Project.select(:path, :'merge_requests.user_id').joins(:merge_requests)

# SELECT "projects"."path", "merge_requests"."id" as user_id FROM "projects" ...
```

Example using Arel (`arel_table`):

```ruby
Project.select(:path, MergeRequest.arel_table[:user_id]).joins(:merge_requests)

# SELECT "projects"."path", "merge_requests"."user_id" FROM "projects" ...
```

When writing raw SQL query:

```sql
SELECT projects.path, merge_requests.user_id FROM "projects"...
```

When the raw SQL query is parameterized (needs escaping):

```ruby
include ActiveRecord::ConnectionAdapters::Quoting

"""
SELECT
  #{quote_table_name('projects')}.#{quote_column_name('path')},
  #{quote_table_name('merge_requests')}.#{quote_column_name('user_id')}
FROM ...
"""
```

### Bad (avoid)

```ruby
Project.select('id, path, user_id').joins(:merge_requests).to_sql

# SELECT id, path, user_id FROM "projects" ...
```

```ruby
Project.select("path", "user_id").joins(:merge_requests)
# SELECT "projects"."path", "user_id" FROM "projects" ...

# or

Project.select(:path, :user_id).joins(:merge_requests)
# SELECT "projects"."path", "user_id" FROM "projects" ...
```

When a column list is given, ActiveRecord tries to match the arguments against the columns defined in the `projects` table and prepend the table name automatically. In this case, the `id` column is not a problem, but the `user_id` column could return unexpected data:

```ruby
Project.select(:id, :user_id).joins(:merge_requests)

# Before deployment (user_id is taken from the merge_requests table):
# SELECT "projects"."id", "user_id" FROM "projects" ...

# After deployment (user_id is taken from the projects table):
# SELECT "projects"."id", "projects"."user_id" FROM "projects" ...
```

## Plucking IDs

Be very careful using ActiveRecord's `pluck` to load a set of values into memory only to
use them as an argument for another query. In general, moving query logic out of PostgreSQL
and into Ruby is detrimental because PostgreSQL has a query optimizer that performs better
when it has relatively more context about the desired operation.

If, for some reason, you need to `pluck` and use the results in a *single* query then,
most likely, a materialized CTE will be a better choice:

```sql
WITH ids AS MATERIALIZED (
  SELECT id FROM table...
)
SELECT * FROM projects
WHERE id IN (SELECT id FROM ids);
```

which will make PostgreSQL pluck the values into an internal array.

Some pluck-related mistakes that you should avoid:

- Passing too many integers into a query. While not explicitly limited, PostgreSQL has a
practical arity limit of a couple thousand IDs. We don't want to run up against this limit.
- Generating gigantic query text that can cause problems for our logging infrastructure.
- Accidentally scanning an entire table. For example, this executes an
extra unnecessary database query and load a lot of unnecessary data into memory:

```ruby
projects = Project.all.pluck(:id)

MergeRequest.where(source_project_id: projects)
```

Instead you can just use sub-queries which perform far better:

```ruby
MergeRequest.where(source_project_id: Project.all.select(:id))
```

A few specific reasons you might choose `pluck`:

- You actually need to operate on the values in Ruby itself. For example, writing them to a file.
- The values get cached or memoized in order to be reused in **multiple related queries**.

In line with our `CodeReuse/ActiveRecord` cop, you should only use forms like
`pluck(:id)` or `pluck(:user_id)` within model code. In the former case, you can
use the `ApplicationRecord`-provided `.pluck_primary_key` helper method instead.
In the latter, you should add a small helper method to the relevant model.

If you have strong reasons to use `pluck`, it could make sense to limit the number
of records plucked. `MAX_PLUCK` defaults to `1_000` in `ApplicationRecord`. In all cases,
you should still consider using a subquery and make sure that using `pluck` is a reliably
better option.

## Inherit from ApplicationRecord

Most models in the GitLab codebase should inherit from `ApplicationRecord`
or `Ci::ApplicationRecord` rather than from `ActiveRecord::Base`. This allows
helper methods to be easily added.

An exception to this rule exists for models created in database migrations. As
these should be isolated from application code, they should continue to subclass
from `MigrationRecord` which is available only in migration context.

## Use UNIONs

`UNION`s aren't very commonly used in most Rails applications but they're very
powerful and useful. Queries tend to use a lot of `JOIN`s to
get related data or data based on certain criteria, but `JOIN` performance can
quickly deteriorate as the data involved grows.

For example, if you want to get a list of projects where the name contains a
value _or_ the name of the namespace contains a value most people would write
the following query:

```sql
SELECT *
FROM projects
JOIN namespaces ON namespaces.id = projects.namespace_id
WHERE projects.name ILIKE '%gitlab%'
OR namespaces.name ILIKE '%gitlab%';
```

Using a large database this query can easily take around 800 milliseconds to
run. Using a `UNION` we'd write the following instead:

```sql
SELECT projects.*
FROM projects
WHERE projects.name ILIKE '%gitlab%'

UNION

SELECT projects.*
FROM projects
JOIN namespaces ON namespaces.id = projects.namespace_id
WHERE namespaces.name ILIKE '%gitlab%';
```

This query in turn only takes around 15 milliseconds to complete while returning
the exact same records.

This doesn't mean you should start using UNIONs everywhere, but it's something
to keep in mind when using lots of JOINs in a query and filtering out records
based on the joined data.

GitLab comes with a `Gitlab::SQL::Union` class that can be used to build a `UNION`
of multiple `ActiveRecord::Relation` objects. You can use this class as
follows:

```ruby
union = Gitlab::SQL::Union.new([projects, more_projects, ...])

Project.from("(#{union.to_sql}) projects")
```

The `FromUnion` model concern provides a more convenient method to produce the same result as above:

```ruby
class Project
  include FromUnion
  ...
end

Project.from_union(projects, more_projects, ...)
```

`UNION` is common through the codebase, but it's also possible to use the other SQL set operators of `EXCEPT` and `INTERSECT`:

```ruby
class Project
  include FromIntersect
  include FromExcept
  ...
end

intersected = Project.from_intersect(all_projects, project_set_1, project_set_2)
excepted = Project.from_except(all_projects, project_set_1, project_set_2)
```

### Uneven columns in the `UNION` sub-queries

When the `UNION` query has uneven columns in the `SELECT` clauses, the database returns an error.
Consider the following `UNION` query:

```sql
SELECT id FROM users WHERE id = 1
UNION
SELECT id, name FROM users WHERE id = 2
end
```

The query results in the following error message:

```plaintext
each UNION query must have the same number of columns
```

This problem is apparent and it can be easily fixed during development. One edge-case is when
`UNION` queries are combined with explicit column listing where the list comes from the
`ActiveRecord` schema cache.

Example (bad, avoid it):

```ruby
scope1 = User.select(User.column_names).where(id: [1, 2, 3]) # selects the columns explicitly
scope2 = User.where(id: [10, 11, 12]) # uses SELECT users.*

User.connection.execute(Gitlab::SQL::Union.new([scope1, scope2]).to_sql)
```

When this code is deployed, it doesn't cause problems immediately. When another
developer adds a new database column to the `users` table, this query breaks in
production and can cause downtime. The second query (`SELECT users.*`) includes the
newly added column; however, the first query does not. The `column_names` method returns stale
values (the new column is missing), because the values are cached within the `ActiveRecord` schema
cache. These values are usually populated when the application boots up.

At this point, the only fix would be a full application restart so that the schema cache gets
updated. Since [GitLab 16.1](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/121957),
the schema cache will be automatically reset so that subsequent queries
will succeed. This reset can be disabled by disabling the `ops` feature
flag `reset_column_information_on_statement_invalid`.

The problem can be avoided if we always use `SELECT users.*` or we always explicitly define the
columns.

Using `SELECT users.*`:

```ruby
# Bad, avoid it
scope1 = User.select(User.column_names).where(id: [1, 2, 3])
scope2 = User.where(id: [10, 11, 12])

# Good, both queries generate SELECT users.*
scope1 = User.where(id: [1, 2, 3])
scope2 = User.where(id: [10, 11, 12])

User.connection.execute(Gitlab::SQL::Union.new([scope1, scope2]).to_sql)
```

Explicit column list definition:

```ruby
# Good, the SELECT columns are consistent
columns = User.cached_column_list # The helper returns fully qualified (table.column) column names (Arel)
scope1 = User.select(*columns).where(id: [1, 2, 3]) # selects the columns explicitly
scope2 = User.select(*columns).where(id: [10, 11, 12]) # uses SELECT users.*

User.connection.execute(Gitlab::SQL::Union.new([scope1, scope2]).to_sql)
```

## Ordering by Creation Date

When ordering records based on the time they were created, you can order
by the `id` column instead of ordering by `created_at`. Because IDs are always
unique and incremented in the order that rows are created, doing so produces the
exact same results. This also means there's no need to add an index on
`created_at` to ensure consistent performance as `id` is already indexed by
default.

## Use `WHERE EXISTS` instead of `WHERE IN`

While `WHERE IN` and `WHERE EXISTS` can be used to produce the same data it is
recommended to use `WHERE EXISTS` whenever possible. While in many cases
PostgreSQL can optimize `WHERE IN` quite well there are also many cases where
`WHERE EXISTS` performs (much) better.

In Rails you have to use this by creating SQL fragments:

```ruby
Project.where('EXISTS (?)', User.select(1).where('projects.creator_id = users.id AND users.foo = X'))
```

This would then produce a query along the lines of the following:

```sql
SELECT *
FROM projects
WHERE EXISTS (
    SELECT 1
    FROM users
    WHERE projects.creator_id = users.id
    AND users.foo = X
)
```

## Query plan flip problem with `.exists?` queries

In Rails, calling `.exists?` on an ActiveRecord scope could cause query plan flip issues, which
could lead to database statement timeouts. When preparing query plans for review, it's advisable to
check all variants of the underlying query form ActiveRecord scopes.

Example: check if there are any epics in the group and its subgroups.

```ruby
# Similar queries, but they might behave differently (different query execution plan)

Epic.where(group_id: group.first.self_and_descendant_ids).order(:id).limit(20) # for pagination
Epic.where(group_id: group.first.self_and_descendant_ids).count # for providing total count
Epic.where(group_id: group.first.self_and_descendant_ids).exists? # for checking if there is at least one epic present
```

When the `.exists?` method is called, Rails modifies the active record scope:

- Replaces the select columns with `SELECT 1`.
- Adds `LIMIT 1` to the query.

When invoked, complex ActiveRecord scopes, such as those with `IN` queries, could negatively alter database query planning behavior.

Execution plan:

```ruby
Epic.where(group_id: group.first.self_and_descendant_ids).exists?
```

```plain
Limit  (cost=126.86..591.11 rows=1 width=4)
  ->  Nested Loop Semi Join  (cost=126.86..3255965.65 rows=7013 width=4)
        Join Filter: (epics.group_id = namespaces.traversal_ids[array_length(namespaces.traversal_ids, 1)])
        ->  Index Only Scan using index_epics_on_group_id_and_iid on epics  (cost=0.42..8846.02 rows=426445 width=4)
        ->  Materialize  (cost=126.43..808.15 rows=435 width=28)
              ->  Bitmap Heap Scan on namespaces  (cost=126.43..805.98 rows=435 width=28)
                    Recheck Cond: ((traversal_ids @> '{9970}'::integer[]) AND ((type)::text = 'Group'::text))
                    ->  Bitmap Index Scan on index_namespaces_on_traversal_ids_for_groups  (cost=0.00..126.32 rows=435 width=0)
                          Index Cond: (traversal_ids @> '{9970}'::integer[])
```

Notice the `Index Only Scan` on the `index_epics_on_group_id_and_iid` index where the planner estimates reading more than 400,000 rows.

If we execute the query without `exists?`, we get a different execution plan:

```ruby
Epic.where(group_id: Group.first.self_and_descendant_ids).to_a
```

Execution plan:

```plain
Nested Loop  (cost=807.49..11198.57 rows=7013 width=1287)
  ->  HashAggregate  (cost=807.06..811.41 rows=435 width=28)
        Group Key: namespaces.traversal_ids[array_length(namespaces.traversal_ids, 1)]
        ->  Bitmap Heap Scan on namespaces  (cost=126.43..805.98 rows=435 width=28)
              Recheck Cond: ((traversal_ids @> '{9970}'::integer[]) AND ((type)::text = 'Group'::text))
              ->  Bitmap Index Scan on index_namespaces_on_traversal_ids_for_groups  (cost=0.00..126.32 rows=435 width=0)
                    Index Cond: (traversal_ids @> '{9970}'::integer[])
  ->  Index Scan using index_epics_on_group_id_and_iid on epics  (cost=0.42..23.72 rows=16 width=1287)
        Index Cond: (group_id = (namespaces.traversal_ids)[array_length(namespaces.traversal_ids, 1)])
```

This query plan doesn't contain the `MATERIALIZE` nodes and uses a more efficient access method by loading the group
hierarchy first.

Query plan flips can be accidentally introduced by even the smallest query change. Revisiting the `.exists?` query where selecting
the group ID database column differently:

```ruby
Epic.where(group_id: group.first.select(:id)).exists?
```

```plain
Limit  (cost=126.86..672.26 rows=1 width=4)
  ->  Nested Loop  (cost=126.86..1763.07 rows=3 width=4)
        ->  Bitmap Heap Scan on namespaces  (cost=126.43..805.98 rows=435 width=4)
              Recheck Cond: ((traversal_ids @> '{9970}'::integer[]) AND ((type)::text = 'Group'::text))
              ->  Bitmap Index Scan on index_namespaces_on_traversal_ids_for_groups  (cost=0.00..126.32 rows=435 width=0)
                    Index Cond: (traversal_ids @> '{9970}'::integer[])
        ->  Index Only Scan using index_epics_on_group_id_and_iid on epics  (cost=0.42..2.04 rows=16 width=4)
              Index Cond: (group_id = namespaces.id)
```

Here we see again the better execution plan. In case we do a small change to the query, it flips again:

```ruby
Epic.where(group_id: group.first.self_and_descendants.select('id + 0')).exists?
```

```plain
Limit  (cost=126.86..591.11 rows=1 width=4)
  ->  Nested Loop Semi Join  (cost=126.86..3255965.65 rows=7013 width=4)
        Join Filter: (epics.group_id = (namespaces.id + 0))
        ->  Index Only Scan using index_epics_on_group_id_and_iid on epics  (cost=0.42..8846.02 rows=426445 width=4)
        ->  Materialize  (cost=126.43..808.15 rows=435 width=4)
              ->  Bitmap Heap Scan on namespaces  (cost=126.43..805.98 rows=435 width=4)
                    Recheck Cond: ((traversal_ids @> '{9970}'::integer[]) AND ((type)::text = 'Group'::text))
                    ->  Bitmap Index Scan on index_namespaces_on_traversal_ids_for_groups  (cost=0.00..126.32 rows=435 width=0)
                          Index Cond: (traversal_ids @> '{9970}'::integer[])
```

Forcing an execution plan is possible if the `IN` subquery is moved to a CTE:

```ruby
cte = Gitlab::SQL::CTE.new(:group_ids, Group.first.self_and_descendant_ids)
Epic.where('epics.id IN (SELECT id FROM group_ids)').with(cte.to_arel).exists?
```

```plain
Limit  (cost=817.27..818.12 rows=1 width=4)
  CTE group_ids
    ->  Bitmap Heap Scan on namespaces  (cost=126.43..807.06 rows=435 width=4)
          Recheck Cond: ((traversal_ids @> '{9970}'::integer[]) AND ((type)::text = 'Group'::text))
          ->  Bitmap Index Scan on index_namespaces_on_traversal_ids_for_groups  (cost=0.00..126.32 rows=435 width=0)
                Index Cond: (traversal_ids @> '{9970}'::integer[])
  ->  Nested Loop  (cost=10.21..380.29 rows=435 width=4)
        ->  HashAggregate  (cost=9.79..11.79 rows=200 width=4)
              Group Key: group_ids.id
              ->  CTE Scan on group_ids  (cost=0.00..8.70 rows=435 width=4)
        ->  Index Only Scan using epics_pkey on epics  (cost=0.42..1.84 rows=1 width=4)
              Index Cond: (id = group_ids.id)
```

NOTE:
Due to their complexity, using CTEs should be the last resort. Use CTEs only when simpler query changes don't produce a favorable execution plan.

## `.find_or_create_by` is not atomic

The inherent pattern with methods like `.find_or_create_by` and
`.first_or_create` and others is that they are not atomic. This means,
it first runs a `SELECT`, and if there are no results an `INSERT` is
performed. With concurrent processes in mind, there is a race condition
which may lead to trying to insert two similar records. This may not be
desired, or may cause one of the queries to fail due to a constraint
violation, for example.

Using transactions does not solve this problem.

To solve this we've added the `ApplicationRecord.safe_find_or_create_by`.

This method can be used the same way as
`find_or_create_by`, but it wraps the call in a *new* transaction (or a subtransaction) and
retries if it were to fail because of an
`ActiveRecord::RecordNotUnique` error.

To be able to use this method, make sure the model you want to use
this on inherits from `ApplicationRecord`.

In Rails 6 and later, there is a
[`.create_or_find_by`](https://api.rubyonrails.org/classes/ActiveRecord/Relation.html#method-i-create_or_find_by)
method. This method differs from our `.safe_find_or_create_by` methods
because it performs the `INSERT`, and then performs the `SELECT` commands only if that call
fails.

If the `INSERT` fails, it leaves a dead tuple around and
increment the primary key sequence (if any), among [other downsides](https://api.rubyonrails.org/classes/ActiveRecord/Relation.html#method-i-create_or_find_by).

We prefer `.safe_find_or_create_by` if the common path is that we
have a single record which is reused after it has first been created.
However, if the more common path is to create a new record, and we only
want to avoid duplicate records to be inserted on edge cases
(for example a job-retry), then `.create_or_find_by` can save us a `SELECT`.

Both methods use subtransactions internally if executed within the context of
an existing transaction. This can significantly impact overall performance,
especially if more than 64 live subtransactions are being used inside a single transaction.

### Can I use `.safe_find_or_create_by`?

If your code is generally isolated (for example it's executed in a worker only) and not wrapped with another transaction, then you can use `.safe_find_or_create_by`. However, there is no tooling to catch cases when someone else calls your code within a transaction. Using `.safe_find_or_create_by` will definitely carry some risks that cannot be eliminated completely at the moment.

Additionally, we have a RuboCop rule `Performance/ActiveRecordSubtransactionMethods` that prevents the usage of `.safe_find_or_create_by`. This rule can be disabled on a case by case basis via `# rubocop:disable Performance/ActiveRecordSubtransactionMethods`.

### Alternatives to .find_or_create_by

#### Alternative 1: `UPSERT`

The [`.upsert`](https://api.rubyonrails.org/v7.0.5/classes/ActiveRecord/Persistence/ClassMethods.html#method-i-upsert) method can be an alternative solution when the table is backed by a unique index.

Simple usage of the `.upsert` method:

```ruby
BuildTrace.upsert(
  {
    build_id: build_id,
    title: title
  },
  unique_by: :build_id
)
```

A few things to be careful about:

- The sequence for the primary key will be incremented, even if the record was only updated.
- The created record is not returned. The `returning` option only returns data when an `INSERT` happens (new record).
- `ActiveRecord` validations are not executed.

An example of the `.upsert` method with validations and record loading:

```ruby
params = {
  build_id: build_id,
  title: title
}

build_trace = BuildTrace.new(params)

unless build_trace.valid?
  raise 'notify the user here'
end

BuildTrace.upsert(params, unique_by: :build_id)

build_trace = BuildTrace.find_by!(build_id: build_id)

# do something with build_trace here
```

The code snippet above will not work well if there is a model-level uniqueness validation on the `build_id` column because we invoke the validation before calling `.upsert`.

To work around this, we have two options:

- Remove the uniqueness validation from the `ActiveRecord` model.
- Use the [`on` keyword](https://guides.rubyonrails.org/active_record_validations.html#on) and implement context-specific validation.

#### Alternative 2: Check existence and rescue

When the chance of concurrently creating the same record is very low, we can use a simpler approach:

```ruby
def my_create_method
  params = {
    build_id: build_id,
    title: title
  }

  build_trace = BuildTrace
    .where(build_id: params[:build_id])
    .first

  build_trace = BuildTrace.new(params) if build_trace.blank?

  build_trace.update!(params)

rescue ActiveRecord::RecordInvalid => invalid
  retry if invalid.record&.errors&.of_kind?(:build_id, :taken)
end
```

The method does the following:

1. Look up the model by the unique column.
1. If no record found, build a new one.
1. Persist the record.

There is a short race condition between the lookup query and the persist query where another process could insert the record and cause an `ActiveRecord::RecordInvalid` exception.

The code rescues this particular exception and retries the operation. For the second run, the record would be successfully located. For example check [this block of code](https://gitlab.com/gitlab-org/gitlab/-/blob/0b51d7fbb97d4becf5fd40bc3b92f732bece85bd/ee/app/services/compliance_management/standards/gitlab/prevent_approval_by_author_service.rb#L20-30) in `PreventApprovalByAuthorService`.

## Monitor SQL queries in production

GitLab team members can monitor slow or canceled queries on GitLab.com
using the PostgreSQL logs, which are indexed in Elasticsearch and
searchable using Kibana.

See [the runbook](https://gitlab.com/gitlab-com/runbooks/-/blob/master/docs/patroni/pg_collect_query_data.md#searching-postgresql-logs-with-kibanaelasticsearch)
for more details.

## When to use common table expressions

You can use common table expressions (CTEs) to create a temporary result set within a more complex query.
You can also use a recursive CTE to reference the CTE's result set within
the query itself. The following example queries a chain of
`personal access tokens` referencing each other in the
`previous_personal_access_token_id` column.

```sql
WITH RECURSIVE "personal_access_tokens_cte" AS (
(
    SELECT
      "personal_access_tokens".*
    FROM
      "personal_access_tokens"
    WHERE
      "personal_access_tokens"."previous_personal_access_token_id" = 15)
  UNION (
    SELECT
      "personal_access_tokens".*
    FROM
      "personal_access_tokens",
      "personal_access_tokens_cte"
    WHERE
      "personal_access_tokens"."previous_personal_access_token_id" = "personal_access_tokens_cte"."id"))
SELECT
  "personal_access_tokens".*
FROM
  "personal_access_tokens_cte" AS "personal_access_tokens"

 id | previous_personal_access_token_id
----+-----------------------------------
 16 |                                15
 17 |                                16
 18 |                                17
 19 |                                18
 20 |                                19
 21 |                                20
(6 rows)
```

As CTEs are temporary result sets, you can use them within another `SELECT`
statement. Using CTEs with `UPDATE`, or `DELETE` could lead to unexpected
behavior:

Consider the following method:

```ruby
def personal_access_token_chain(token)
  cte = Gitlab::SQL::RecursiveCTE.new(:personal_access_tokens_cte)
  personal_access_token_table = Arel::Table.new(:personal_access_tokens)

  cte << PersonalAccessToken
           .where(personal_access_token_table[:previous_personal_access_token_id].eq(token.id))
  cte << PersonalAccessToken
           .from([personal_access_token_table, cte.table])
           .where(personal_access_token_table[:previous_personal_access_token_id].eq(cte.table[:id]))
  PersonalAccessToken.with.recursive(cte.to_arel).from(cte.alias_to(personal_access_token_table))
end
```

It works as expected when it is used to query data:

```sql
> personal_access_token_chain(token)

WITH RECURSIVE "personal_access_tokens_cte" AS (
(
    SELECT
      "personal_access_tokens".*
    FROM
      "personal_access_tokens"
    WHERE
      "personal_access_tokens"."previous_personal_access_token_id" = 11)
  UNION (
    SELECT
      "personal_access_tokens".*
    FROM
      "personal_access_tokens",
      "personal_access_tokens_cte"
    WHERE
      "personal_access_tokens"."previous_personal_access_token_id" = "personal_access_tokens_cte"."id"))
SELECT
    "personal_access_tokens".*
FROM
    "personal_access_tokens_cte" AS "personal_access_tokens"
```

However, the CTE is dropped when used with `#update_all`. As a result, the method
updates the entire table:

```sql
> personal_access_token_chain(token).update_all(revoked: true)

UPDATE
    "personal_access_tokens"
SET
    "revoked" = TRUE
```

To work around this behavior:

1. Query the `ids` of the records:

   ```ruby
   > token_ids = personal_access_token_chain(token).pluck_primary_key
   => [16, 17, 18, 19, 20, 21]
   ```

1. Use this array to scope `PersonalAccessTokens`:

   ```ruby
   PersonalAccessToken.where(id: token_ids).update_all(revoked: true)
   ```

Alternatively, combine these two steps:

```ruby
PersonalAccessToken
  .where(id: personal_access_token_chain(token).pluck_primary_key)
  .update_all(revoked: true)
```

NOTE:
Avoid updating large volumes of unbounded data. If there are no [application limits](application_limits.md) on the data, or you are unsure about the data volume, you should [update the data in batches](database/iterating_tables_in_batches.md).
