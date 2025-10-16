---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/development/development_processes/#development-guidelines-review.
title: ClickHouse within GitLab
---

This document gives a high-level overview of how to develop features using ClickHouse in the GitLab Rails application.

{{< alert type="note" >}}

Most of the tooling and APIs are considered unstable.

{{< /alert >}}

## GDK setup

### Setup ClickHouse server

1. Install ClickHouse locally as described in [ClickHouse installation documentation](https://clickhouse.com/docs/en/install). If you use QuickInstall it will be installed in current directory, if you use Homebrew it will be installed to `/opt/homebrew/bin/clickhouse`
1. Add ClickHouse section to your `gdk.yml`. See [`gdk.example.yml`](https://gitlab.com/gitlab-org/gitlab-development-kit/-/blob/main/gdk.example.yml)
1. Adjust the `gdk.yml` ClickHouse configuration file to point to your local ClickHouse installation and local data storage. E.g.

   ```yaml
   clickhouse:
     bin: "/opt/homebrew/bin/clickhouse"
     enabled: true
     # these are optional if we have more then one GDK:
     # http_port: 8123
     # interserver_http_port: 9009
     # tcp_port: 9001
   ```

1. Run `gdk reconfigure`
1. Start ClickHouse with `gdk start clickhouse`

### Configure your Rails application

1. Copy the example file and configure the credentials:

   ```shell
   cp config/click_house.yml.example config/click_house.yml
   ```

1. Create the database using the bundled `clickhouse client`:

   ```shell
   gdk clickhouse
   ```

   ```sql
   create database gitlab_clickhouse_development;
   create database gitlab_clickhouse_test;
   ```

### Validate your setup

Run the Rails console and invoke a simple query:

```ruby
ClickHouse::Client.select('SELECT 1', :main)
# => [{"1"=>1}]
```

## Database schema and migrations

To generate a ClickHouse database migration, execute:

``` shell
bundle exec rails generate gitlab:click_house:migration MIGRATION_CLASS_NAME
```

To run database migrations, execute:

```shell
bundle exec rake gitlab:clickhouse:migrate
```

To rollback last N migrations, execute:

```shell
bundle exec rake gitlab:clickhouse:rollback:main STEP=N
```

Or use the following command to rollback all migrations:

```shell
bundle exec rake gitlab:clickhouse:rollback:main VERSION=0
```

You can create a migration by creating a Ruby migration file in `db/click_house/migrate` folder. It should be prefixed with a timestamp in the format `YYYYMMDDHHMMSS_description_of_migration.rb`

```ruby
# 20230811124511_create_issues.rb
# frozen_string_literal: true

class CreateIssues < ClickHouse::Migration
  def up
    execute <<~SQL
      CREATE TABLE issues
      (
        id UInt64 DEFAULT 0,
        title String DEFAULT ''
      )
      ENGINE = MergeTree
      PRIMARY KEY (id)
    SQL
  end

  def down
    execute <<~SQL
      DROP TABLE sync_cursors
    SQL
  end
end
```

## Post deployment migrations

To generate a ClickHouse database post deployment migration execute:

``` shell
bundle exec rails generate gitlab:click_house:post_deployment_migration MIGRATION_CLASS_NAME
```

These migrations will run by default together with regular migrations, but they can be skipped,
for example, before deploying to production using `SKIP_POST_DEPLOYMENT_MIGRATIONS` environment variable, for example:

``` shell
export SKIP_POST_DEPLOYMENT_MIGRATIONS=true
bundle exec rake gitlab:clickhouse:migrate
```

## Writing database queries

For the ClickHouse database we don't use ORM (Object Relational Mapping). The main reason is that the GitLab application has many customizations for the `ActiveRecord` PostgreSQL adapter and the application generally assumes that all databases are using `PostgreSQL`. Since ClickHouse-related features are still in a very early stage of development, we decided to implement a simple HTTP client to avoid hard to discover bugs and long debugging time when dealing with multiple `ActiveRecord` adapters.

Additionally, ClickHouse might not be used the same way as other adapters for `ActiveRecord`. The access patterns differ from traditional transactional databases, in that ClickHouse:

- Uses nested aggregation `SELECT` queries with `GROUP BY` clauses.
- Doesn't use single `INSERT` statements. Data is inserted in batches via background jobs.
- Has different consistency characteristics, no transactions.
- Has very little database-level validations.

Database queries are written and executed with the help of the `ClickHouse::Client` gem.

A simple query from the `events` table:

```ruby
rows = ClickHouse::Client.select('SELECT * FROM events', :main)
```

When working with queries with placeholders you can use the `ClickHouse::Query` object where you need to specify the placeholder name and its data type. The actual variable replacement, quoting and escaping will be done by the ClickHouse server.

```ruby
raw_query = 'SELECT * FROM events WHERE id > {min_id:UInt64}'
placeholders = { min_id: Integer(100) }
query = ClickHouse::Client::Query.new(raw_query: raw_query, placeholders: placeholders)

rows = ClickHouse::Client.select(query, :main)
```

When using placeholders the client can provide the query with redacted placeholder values which can be ingested by our logging system. You can see the redacted version of your query by calling the `to_redacted_sql` method:

```ruby
puts query.to_redacted_sql
```

ClickHouse allows only one statement per request. This means that the common SQL injection vulnerability where the statement is closed with a `;` character and then another query is "injected" cannot be exploited:

```ruby
ClickHouse::Client.select('SELECT 1; SELECT 2', :main)

# ClickHouse::Client::DatabaseError: Code: 62. DB::Exception: Syntax error (Multi-statements are not allowed): failed at position 9 (end of query): ; SELECT 2. . (SYNTAX_ERROR) (version 23.4.2.11 (official build))
```

### Subqueries

You can compose complex queries with the `ClickHouse::Client::Query` class by specifying the query placeholder with the special `Subquery` type. The library will make sure to correctly merge the queries and the placeholders:

```ruby
subquery = ClickHouse::Client::Query.new(raw_query: 'SELECT id FROM events WHERE id = {id:UInt64}', placeholders: { id: Integer(10) })

raw_query = 'SELECT * FROM events WHERE id > {id:UInt64} AND id IN ({q:Subquery})'
placeholders = { id: Integer(10), q: subquery }

query = ClickHouse::Client::Query.new(raw_query: raw_query, placeholders: placeholders)
rows = ClickHouse::Client.select(query, :main)

# ClickHouse will replace the placeholders
puts query.to_sql # SELECT * FROM events WHERE id > {id:UInt64} AND id IN (SELECT id FROM events WHERE id = {id:UInt64})

puts query.to_redacted_sql # SELECT * FROM events WHERE id > $1 AND id IN (SELECT id FROM events WHERE id = $2)

puts query.placeholders # { id: 10 }
```

In case there are placeholders with the same name but different values the query will raise an error.

### Writing query conditions

When working with complex forms where multiple filter conditions are present, building queries by concatenating query fragments as string can get out of hands very quickly. For queries with several conditions you may use the `ClickHouse::Client::QueryBuilder` class. The class uses the `Arel` gem to generate queries and provides a similar query interface like `ActiveRecord`.

```ruby
builder = ClickHouse::Client::QueryBuilder.new('events')

query = builder
  .where(builder.table[:created_at].lteq(Date.today))
  .where(id: [1,2,3])

rows = ClickHouse::Client.select(query, :main)
```

## Inserting data

The ClickHouse client supports inserting data through the standard query interface:

```ruby
raw_query = 'INSERT INTO events (id, target_type) VALUES ({id:UInt64}, {target_type:String})'
placeholders = { id: 1, target_type: 'Issue' }

query = ClickHouse::Client::Query.new(raw_query: raw_query, placeholders: placeholders)
rows = ClickHouse::Client.execute(query, :main)
```

Inserting data this way is acceptable if:

- The table contains settings or configuration data where we need to add one row.
- For testing, test data has to be prepared in the database.

When inserting data, we should always try to use batch processing where multiple rows are inserted at once. Building large `INSERT` queries in memory is discouraged because of the increased memory usage. Additionally, values specified within such queries cannot be redacted automatically by the client.

To compress data and reduce memory usage, insert CSV data. You can do this with the internal [`CsvBuilder`](https://gitlab.com/gitlab-org/gitlab/-/tree/master/gems/csv_builder) gem:

```ruby
iterator = Event.find_each

# insert from events table using only the id and the target_type columns
column_mapping = {
  id: :id,
  target_type: :target_type
}

CsvBuilder::Gzip.new(iterator, column_mapping).render do |tempfile|
  query = 'INSERT INTO events (id, target_type) FORMAT CSV'
  ClickHouse::Client.insert_csv(query, File.open(tempfile.path), :main)
end
```

{{< alert type="note" >}}

It's important to test and verify efficient batching of database records from PostgreSQL. Consider using the techniques described in the [Iterating tables in batches](../iterating_tables_in_batches.md).

{{< /alert >}}

## Iterating over tables

You can use the `ClickHouse::Iterator` class for batching over large volumes of data in ClickHouse. The iterator works a bit differently than existing tooling for the PostgreSQL database (see [iterating tables in batches docs](../iterating_tables_in_batches.md)), as the tool does not rely on database indexes and uses fixed size numeric ranges.

Prerequisites:

- Single integer column.
- No huge gaps between the column values, the ideal columns would be auto-incrementing PostgreSQL primary keys.
- Duplicated values are not a problem if the data duplication is minimal.

Usage:

```ruby
connection = ClickHouse::Connection.new(:main)
builder = ClickHouse::Client::QueryBuilder.new('events')

iterator = ClickHouse::Iterator.new(query_builder: builder, connection: connection)
iterator.each_batch(column: :id, of: 100_000) do |scope|
  records = connection.select(scope.to_sql)
end
```

In case you want to iterate over specific rows, you could add filters to the query builder object. Be advised that efficient filtering and iteration might require a different database table schema optimized for the use case. When introducing such iteration, always ensure that the database queries are not scanning the whole database table.

```ruby
connection = ClickHouse::Connection.new(:main)
builder = ClickHouse::Client::QueryBuilder.new('events')

# filtering by target type and stringified traversal ids/path
builder = builder.where(target_type: 'Issue')
builder = builder.where(path: '96/97/') # points to a specific project

iterator = ClickHouse::Iterator.new(query_builder: builder, connection: connection)
iterator.each_batch(column: :id, of: 10) do |scope, min, max|
  puts "processing range: #{min} - #{max}"
  puts scope.to_sql
  records = connection.select(scope.to_sql)
end
```

### Min-max strategies

As the first step, the iterator determines the data range which will be used as condition in the iteration database queries. The data range is
determined using `MIN(column)` and `MAX(column)` aggregations. For some database tables this strategy causes inefficient database queries (full table scan). One example would be partitioned database tables.

Example query:

```sql
SELECT MIN(id) AS min, MAX(id) AS max FROM events;
```

Alternatively a different min-max strategy can be used which uses `ORDER BY + LIMIT` for determining the data range.

```ruby
iterator = ClickHouse::Iterator.new(query_builder: builder, connection: connection, min_max_strategy: :order_limit)
```

Example query:

```sql
SELECT (SELECT id FROM events ORDER BY id ASC LIMIT 1) AS min, (SELECT id FROM events ORDER BY id DESC LIMIT 1) AS max;
```

## Implementing Sidekiq workers

Sidekiq workers leveraging ClickHouse databases should include the `ClickHouseWorker` module.
This ensures that the worker is paused while database migrations are running,
and that migrations do not run while the worker is active.

```ruby
# events_sync_worker.rb
# frozen_string_literal: true

module ClickHouse
  class EventsSyncWorker
    include ApplicationWorker
    include ClickHouseWorker

    ...
  end
end
```

### ClickHouse worker tagging

All ClickHouse-related Sidekiq workers are tagged with the `clickhouse` tag to enable customers to move these workers to a separate Sidekiq shard for better resource isolation and performance optimization.

The `tags` metadata field should be added to all workers that interact with ClickHouse:

```ruby
# events_sync_worker.rb
# frozen_string_literal: true

module ClickHouse
  class EventsSyncWorker
    include ApplicationWorker
    include ClickHouseWorker

    idempotent!
    queue_namespace :cronjob
    data_consistency :delayed
    feature_category :value_stream_management
    tags :clickhouse

    def perform
      # Worker implementation
    end
  end
end
```

This tagging allows customers to:

- Route ClickHouse workers to dedicated Sidekiq processes or servers
- Apply different resource limits and scaling policies to ClickHouse workloads
- Monitor and troubleshoot ClickHouse-related background jobs separately
- Implement custom retry policies or error handling for ClickHouse operations

For more information about Sidekiq worker tagging and routing, see the [Sidekiq documentation](../../sidekiq/_index.md).

## GraphQL usage

Use GraphQL to paginate ClickHouse queries with the same external interface as
`ActiveRecord` queries (keyset pagination).

The pagination interface includes:

- `PageInfo` for pagination-specific data (`endCursor` and `startCursor`).
- `after`, `before`, `first`, `last` arguments for loading next or previous pages.

To use GraphQL pagination with ClickHouse, ensure your queries meet these
requirements:

- `ORDER BY` columns must be `NOT NULL`.
- `ORDER BY` direction must be the same for all columns.
- `ORDER BY` column values must identify exactly one row (requirement for
  keyset pagination).

### Resolver implementation example

The GraphQL resolver must return a `ClickHouse::Client::QueryBuilder` object:

```ruby
def resolve
  ClickHouse::Client::QueryBuilder
    .new('events')
    .order(:created_at, :asc)
    .order(:id, :asc)
end
```

The pagination library handles cursor encoding and decoding. The returned data
matches the format you get from a direct ClickHouse query: an array of hashes.
To format the data for GraphQL responses, implement formatting logic in your
GraphQL types.

### Resolver implementation with a deduplicating query

When you query a `ReplacingMergeTree` engine with `version` and `deleted` columns,
you must deduplicate rows by the primary keys. Use a nested `SELECT` with
`GROUP BY` and [`argMax`](https://clickhouse.com/docs/sql-reference/aggregate-functions/reference/argmax)
for deduplication logic.

The following example lists issues filtered by `gitlab-org` group from the
`hierarchy_work_items` materialized view table:

```ruby
def resolve
  builder = ClickHouse::Client::QueryBuilder.new('hierarchy_work_items')

  columns = %i[id title traversal_path work_item_type_id created_at]
  deleted_column = :deleted
  version_column = :version
  group_by_columns = %i[traversal_path work_item_type_id id]

  # Use argMax to determine the latest column value based on the version column.
  inner_projections = columns.map do |column|
    if group_by_columns.include?(column)
      builder.table[column]
    else
      Arel::Nodes::NamedFunction.new('argMax', [
        builder.table[column],
        builder.table[version_column]
      ]).as(column.to_s)
    end
  end

  # Add the deleted column to filter deleted rows later.
  inner_projections << Arel::Nodes::NamedFunction.new('argMax', [
    builder.table[deleted_column],
    builder.table[version_column]
  ]).as(deleted_column.to_s)

  # Select all issues within the gitlab-org group (9970).
  inner_query = builder
    .select(*inner_projections)
    .where(Arel::Nodes::NamedFunction.new('startsWith', [builder.table[:traversal_path], Arel.sql("'1/9970/'")]))
    .where(work_item_type_id: 1)
    .group(*group_by_columns)

  builder
    .select(*columns)
    .from(inner_query, 'hierarchy_work_items')
    .where(deleted: false)
    .order(:created_at, :desc)
    .order(:id, :desc)
end
```

This code generates the following SQL query:

```sql
SELECT
    `hierarchy_work_items`.`id`,
    `hierarchy_work_items`.`title`,
    `hierarchy_work_items`.`traversal_path`,
    `hierarchy_work_items`.`work_item_type_id`,
    `hierarchy_work_items`.`created_at`
FROM
    (
        SELECT
            `hierarchy_work_items`.`id`,
            argMax(
                `hierarchy_work_items`.`title`,
                `hierarchy_work_items`.`version`
            ) AS title,
            `hierarchy_work_items`.`traversal_path`,
            `hierarchy_work_items`.`work_item_type_id`,
            argMax(
                `hierarchy_work_items`.`created_at`,
                `hierarchy_work_items`.`version`
            ) AS created_at,
            argMax(
                `hierarchy_work_items`.`deleted`,
                `hierarchy_work_items`.`version`
            ) AS deleted
        FROM
            `hierarchy_work_items`
        WHERE
            startsWith(
                `hierarchy_work_items`.`traversal_path`,
                '1/9970/'
            )
            AND `hierarchy_work_items`.`work_item_type_id` = 1
        GROUP BY
            traversal_path,
            work_item_type_id,
            id
    ) hierarchy_work_items
WHERE
    `hierarchy_work_items`.`deleted` = 'false'
ORDER BY
    `hierarchy_work_items`.`created_at` DESC,
    `hierarchy_work_items`.`id` DESC
LIMIT
    21
```

## Best practices

When building features that require data from ClickHouse, you should first replicate raw data from PostgreSQL tables (such as events or issues) using [Sidekiq workers](#implementing-sidekiq-workers) or another strategy. Then, build separate aggregations on top of that data. By avoiding direct aggregation from PostgreSQL, you can improve maintainability and enable data reprocessing.

## Testing

ClickHouse is enabled on CI/CD but to avoid significantly affecting the pipeline runtime we've decided to run the ClickHouse server for test cases tagged with `:click_house` only.

The `:click_house` tag ensures that the database schema is properly set up before every test case.

```ruby
RSpec.describe MyClickHouseFeature, :click_house do
  it 'returns rows' do
    rows = ClickHouse::Client.select('SELECT 1', :main)
    expect(rows.size).to eq(1)
  end
end
```

## Multiple databases

By design, the `ClickHouse::Client` library supports configuring multiple databases. Because we're still at a very early stage of development, we only have one database called `main`.

Multi database configuration example:

```yaml
development:
  main:
    database: gitlab_clickhouse_main_development
    url: 'http://localhost:8123'
    username: clickhouse
    password: clickhouse

  user_analytics: # made up database
    database: gitlab_clickhouse_user_analytics_development
    url: 'http://localhost:8123'
    username: clickhouse
    password: clickhouse
```

## Observability

All queries executed via the `ClickHouse::Client` library expose the query with performance metrics (timings, read bytes) via `ActiveSupport::Notifications`.

```ruby
ActiveSupport::Notifications.subscribe('sql.click_house') do |_, _, _, _, data|
  puts data.inspect
end
```

Additionally, to view the executed ClickHouse queries in web interactions, on the performance bar, next to the `ch` label select the count.

## Handling Siphon Errors in Tests

GitLab uses a tool called [Siphon](https://gitlab.com/gitlab-org/analytics-section/siphon) to constantly synchronise data from specified tables in PostgreSQL to ClickHouse.
This process requires that for each specified table, the ClickHouse schema must contain a copy of the PostgreSQL schema.

During GitLab development, if you add a new column to PostgreSQL without adding a matching column in ClickHouse it will fail with an error:

```plaintext
This table is synchronised to ClickHouse and you've added a new column!
```

To resolve this, you should add a migration to add the column to ClickHouse too.

### Example

1. Add a new column `new_int` of type `int4`  to a table that is being synchronised to ClickHouse, such as `milestones`.
1. Note that CI will fail with the error:

   ```plaintext
   This table is synchronised to ClickHouse and you've added a new column!
   ```

1. Generate a new ClickHouse migration to add the new column, note that the ClickHouse table is prefixed with `siphon_`:

   ```plaintext
   bundle exec rails generate gitlab:click_house:migration add_new_int_to_siphon_milestones
   ```

1. In the generated file, define up/down methods to add/remove the new column. ClickHouse data types map approximately to PostgreSQL.
   Check `Gitlab::ClickHouse::SiphonGenerator::PG_TYPE_MAP` for the appropriate mapping for the new column. Using the wrong type will trigger a different error.
   Additionally, consider making use of [`LowCardinaility`](https://clickhouse.com/docs/sql-reference/data-types/lowcardinality) where appropriate and use [`Nullable`](https://clickhouse.com/docs/sql-reference/data-types/nullable) sparingly opting for default values instead where possible.

   ```ruby
    class AddNewIntToSiphonMilestones < ClickHouse::Migration
      def up
        execute <<~SQL
          ALTER TABLE siphon_milestones ADD COLUMN new_int Int64 DEFAULT 42;
        SQL
      end

      def down
        execute <<~SQL
          ALTER TABLE siphon_milestones DROP COLUMN new_int;
        SQL
      end
    end
   ```

If you need further assistance, reach out to `#f_siphon` internally.

## Troubleshooting

If you experience `MEMORY_LIMIT_EXCEEDED` errors when executing queries, increase the `clickhouse.max_memory_usage` and `clickhouse.max_server_memory_usage` settings
in your `gdk.yml` file.

Consult the `gdk.example.yml` file for the default settings. You must reconfigure GDK for changes to take effect.

## Getting help

For additional information or specific questions, reach out to the ClickHouse Datastore working group in the `#f_clickhouse` Slack channel, or mention `@gitlab-org/maintainers/clickhouse` in a comment on GitLab.com.
