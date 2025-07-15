---
stage: Data Access
group: Database Frameworks
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/development/development_processes/#development-guidelines-review.
title: SQL views
---

## Overview

At GitLab, we use SQL views as an abstraction layer over PostgreSQL's system catalogs (`pg_*` tables). This makes it easier to query the system catalogs from Rails.

## Example

For example, the SQL view `postgres_sequences` is an abstraction layer over `pg_sequence` and other `pg_*` tables. It's queried using the following Rails model:

```ruby
module Gitlab
  module Database
    # Backed by the postgres_sequences view
    class PostgresSequence < SharedModel
      self.primary_key = :seq_name

      scope :by_table_name, ->(table_name) { where(table_name: table_name) }
      scope :by_col_name, ->(col_name) { where(col_name: col_name) }
    end
  end
end
```

This allows us to manage database maintenance tasks through Ruby code:

```ruby
Gitlab::Database::PostgresSequence.by_table_name('web_hook_logs')
=> #<Gitlab::Database::PostgresSequence:0x0000000301a1d7a0
  seq_name: "web_hook_logs_id_seq",
  table_name: "web_hook_logs",
  col_name: "id",
  seq_max: 9223372036854775807,
  seq_min: 1,
  seq_start: 1>
```

## Benefits

Using these views provides several advantages:

1. **ActiveRecord Integration**: Complex PostgreSQL metadata queries are wrapped in familiar ActiveRecord models
1. **Maintenance Automation**: Enables automated database maintenance tasks through Ruby code
1. **Monitoring**: Simplifies database health monitoring and metrics collection
1. **Consistency**: Provides a standardized interface for database operations

## Drawbacks

1. **Performance overhead**: Views can introduce additional query overhead due to materialization and computation on access.
1. **Debugging complexity**: Debugging can become more challenging because you need to trace through both the Ruby/Rails layer and the PostgreSQL.
1. **Migration challenges**: Views need to be managed carefully during schema migrations. If underlying tables change, you need to ensure views are updated accordingly. Rails migrations don't handle views as seamlessly as they handle regular tables.
1. **Maintenance overhead**: Views add another layer of programming languages to maintain in your database schema.
1. **Testing complexity**: Testing code that relies on views often requires more testing setup.

## Guidelines

When working with views, always use ActiveRecord models with appropriate scopes and relationships instead of raw SQL queries. Views are read-only by design. When adding new views, ensure proper migrations, models, tests, and documentation are in place.

## Testing

When testing views, use the `swapout_view_for_table` helper to temporarily replace a view with a table.
This way you can use factories to create records similar to ones returned by the view.

```ruby
RSpec.describe Gitlab::Database::PostgresSequence do
  include Database::DatabaseHelpers

  before do
    swapout_view_for_table(:postgres_sequences, connection: ApplicationRecord.connection)
  end
end
```

## Further Reading

- [PostgreSQL System Catalogs](https://www.postgresql.org/docs/16/catalogs.html)
- [PostgreSQL Views](https://www.postgresql.org/docs/16/sql-createview.html)
