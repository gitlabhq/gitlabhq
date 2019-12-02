# SQL Query Guidelines

This document describes various guidelines to follow when writing SQL queries,
either using ActiveRecord/Arel or raw SQL queries.

## Using LIKE Statements

The most common way to search for data is using the `LIKE` statement. For
example, to get all issues with a title starting with "WIP:" you'd write the
following query:

```sql
SELECT *
FROM issues
WHERE title LIKE 'WIP:%';
```

On PostgreSQL the `LIKE` statement is case-sensitive. To perform a case-insensitive
`LIKE` you have to use `ILIKE` instead.

To handle this automatically you should use `LIKE` queries using Arel instead
of raw SQL fragments, as Arel automatically uses `ILIKE` on PostgreSQL.

```ruby
Issue.where('title LIKE ?', 'WIP:%')
```

You'd write this instead:

```ruby
Issue.where(Issue.arel_table[:title].matches('WIP:%'))
```

Here `matches` generates the correct `LIKE` / `ILIKE` statement depending on the
database being used.

If you need to chain multiple `OR` conditions you can also do this using Arel:

```ruby
table = Issue.arel_table

Issue.where(table[:title].matches('WIP:%').or(table[:foo].matches('WIP:%')))
```

On PostgreSQL, this produces:

```sql
SELECT *
FROM issues
WHERE (title ILIKE 'WIP:%' OR foo ILIKE 'WIP:%')
```

## LIKE & Indexes

PostgreSQL won't use any indexes when using `LIKE` / `ILIKE` with a wildcard at
the start. For example, this will not use any indexes:

```sql
SELECT *
FROM issues
WHERE title ILIKE '%WIP:%';
```

Because the value for `ILIKE` starts with a wildcard the database is not able to
use an index as it doesn't know where to start scanning the indexes.

Luckily, PostgreSQL _does_ provide a solution: trigram GIN indexes. These
indexes can be created as follows:

```sql
CREATE INDEX [CONCURRENTLY] index_name_here
ON table_name
USING GIN(column_name gin_trgm_ops);
```

The key here is the `GIN(column_name gin_trgm_ops)` part. This creates a [GIN
index](https://www.postgresql.org/docs/current/gin.html) with the operator class set to `gin_trgm_ops`. These indexes
_can_ be used by `ILIKE` / `LIKE` and can lead to greatly improved performance.
One downside of these indexes is that they can easily get quite large (depending
on the amount of data indexed).

To keep naming of these indexes consistent please use the following naming
pattern:

```
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
class MigrationName < ActiveRecord::Migration[4.2]
  disable_ddl_transaction!
end
```

For example:

```ruby
class AddUsersLowerUsernameEmailIndexes < ActiveRecord::Migration[4.2]
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

Later on, a new feature adds an extra column to the `projects` table: `user_id`. During deployment there might be a short time window where the database migration is already executed, but the new version of the application code is not deployed yet. When the query mentioned above executes during this period, the query will fail with the following error message: `PG::AmbiguousColumn: ERROR: column reference "user_id" is ambiguous`

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

When a column list is given, ActiveRecord tries to match the arguments against the columns defined in the `projects` table and prepend the table name automatically. In this case, the `id` column is not going to be a problem, but the `user_id` column could return unexpected data:

```ruby
Project.select(:id, :user_id).joins(:merge_requests)

# Before deployment (user_id is taken from the merge_requests table):
# SELECT "projects"."id", "user_id" FROM "projects" ...

# After deployment (user_id is taken from the projects table):
# SELECT "projects"."id", "projects"."user_id" FROM "projects" ...
```

## Plucking IDs

This can't be stressed enough: **never** use ActiveRecord's `pluck` to pluck a
set of values into memory only to use them as an argument for another query. For
example, this will make the database **very** sad:

```ruby
projects = Project.all.pluck(:id)

MergeRequest.where(source_project_id: projects)
```

Instead you can just use sub-queries which perform far better:

```ruby
MergeRequest.where(source_project_id: Project.all.select(:id))
```

The _only_ time you should use `pluck` is when you actually need to operate on
the values in Ruby itself (e.g. write them to a file). In almost all other cases
you should ask yourself "Can I not just use a sub-query?".

In line with our `CodeReuse/ActiveRecord` cop, you should only use forms like
`pluck(:id)` or `pluck(:user_id)` within model code. In the former case, you can
use the `ApplicationRecord`-provided `.pluck_primary_key` helper method instead.
In the latter, you should add a small helper method to the relevant model.

## Inherit from ApplicationRecord

Most models in the GitLab codebase should inherit from `ApplicationRecord`,
rather than from `ActiveRecord::Base`. This allows helper methods to be easily
added.

An exception to this rule exists for models created in database migrations. As
these should be isolated from application code, they should continue to subclass
from `ActiveRecord::Base`.

## Use UNIONs

UNIONs aren't very commonly used in most Rails applications but they're very
powerful and useful. In most applications queries tend to use a lot of JOINs to
get related data or data based on certain criteria, but JOIN performance can
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
run. Using a UNION we'd write the following instead:

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

GitLab comes with a `Gitlab::SQL::Union` class that can be used to build a UNION
of multiple `ActiveRecord::Relation` objects. You can use this class as
follows:

```ruby
union = Gitlab::SQL::Union.new([projects, more_projects, ...])

Project.from("(#{union.to_sql}) projects")
```

## Ordering by Creation Date

When ordering records based on the time they were created you can simply order
by the `id` column instead of ordering by `created_at`. Because IDs are always
unique and incremented in the order that rows are created this will produce the
exact same results. This also means there's no need to add an index on
`created_at` to ensure consistent performance as `id` is already indexed by
default.

## Use WHERE EXISTS instead of WHERE IN

While `WHERE IN` and `WHERE EXISTS` can be used to produce the same data it is
recommended to use `WHERE EXISTS` whenever possible. While in many cases
PostgreSQL can optimise `WHERE IN` quite well there are also many cases where
`WHERE EXISTS` will perform (much) better.

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

This method can be used just as you would the normal
`find_or_create_by` but it wraps the call in a *new* transaction and
retries if it were to fail because of an
`ActiveRecord::RecordNotUnique` error.

To be able to use this method, make sure the model you want to use
this on inherits from `ApplicationRecord`.
