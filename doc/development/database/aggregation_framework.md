---
stage: Analytics
group: Optimize
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/development/development_processes/#development-guidelines-review.
title: Aggregations Framework
---

The Aggregation Framework provides a unified interface for building analytical queries across different database backends. It supports both PostgreSQL (via ActiveRecord) and ClickHouse, allowing developers to define reusable aggregation engines with metrics, dimensions, and filters.

## Defining ActiveRecord Engine

The ActiveRecord engine (`Gitlab::Database::Aggregation::ActiveRecord::Engine`) generates PostgreSQL queries using ActiveRecord's query interface.

### Example ActiveRecord Engine

```ruby
class IssueAggregationEngine < Gitlab::Database::Aggregation::ActiveRecord::Engine
  filters do
    exact_match :project_id, :integer, description: 'Filter by project ID'
    exact_match :state, :string, description: 'Filter by issue state'
  end

  dimensions do
    column :author_id, :integer, description: 'Group by author'
    date_bucket :created_at, :datetime,
      parameters: { granularity: { in: %i[daily weekly monthly yearly], type: :string } },
      description: 'Group by creation date'
  end

  metrics do
    count description: 'Total number of issues'
    mean :weight, :float, description: 'Average issue weight'
  end
end
```

The ActiveRecord engine generates a single-level SQL query:

```sql
SELECT
  "issues"."author_id" AS aeq_author_id,
  date_trunc('month', "issues"."created_at") AS aeq_created_at,
  COUNT(*) AS aeq_total_count,
  AVG("issues"."weight") AS aeq_mean_weight
FROM "issues"
WHERE "issues"."project_id" IN (1, 2, 3)
  AND "issues"."state" IN ('opened')
GROUP BY aeq_author_id, aeq_created_at
ORDER BY aeq_author_id, aeq_created_at
```

Key characteristics:

- All columns are prefixed with `aeq_` (Aggregation Engine Query). This prefix is removed by `AggregationResult` object.
- Filters are applied as `WHERE` or `HAVING` clauses
- Dimensions become `GROUP BY` columns
- Metrics use aggregate functions (`COUNT`, `AVG`)

### Available Components

#### `count` metric

Counts rows using `COUNT(*)`.

| Option | Type | Required | Description |
|--------|------|----------|-------------|
| `name` | Symbol | No | Name for the count metric. Default: `'total'`. Identifier becomes `:{name}_count` |
| `type` | Symbol | No | Data type. Default: `:integer` |
| `formatter` | Proc | No | Formatting function applied to results |
| `description` | String | No | Human-readable description |

#### `mean` metric

Calculates the average value using `AVG()`.

| Option | Type | Required | Description |
|--------|------|----------|-------------|
| `name` | Symbol | Yes | Column name to average. Identifier becomes `:mean_{name}` |
| `type` | Symbol | No | Data type. Default: `:float` |
| `expression` | Proc | No | Custom Arel expression instead of column |
| `scope_proc` | Proc | No | Modifies the ActiveRecord scope (e.g., for JOINs) |
| `formatter` | Proc | No | Formatting function applied to results |
| `description` | String | No | Human-readable description |

#### `column` dimension

Groups results by a column value.

| Option | Type | Required | Description |
|--------|------|----------|-------------|
| `name` | Symbol | Yes | Column name or identifier |
| `type` | Symbol | Yes | Data type (`:string`, `:integer`, `:datetime`, etc.) |
| `expression` | Proc | No | Custom Arel expression instead of column |
| `scope_proc` | Proc | No | Modifies the ActiveRecord scope (e.g., for JOINs) |
| `formatter` | Proc | No | Formatting function applied to results |
| `description` | String | No | Human-readable description |

#### `date_bucket` dimension

Groups results by time intervals using PostgreSQL's `date_trunc()` function. **Supports parameters.**

| Option | Type | Required | Description |
|--------|------|----------|-------------|
| `name` | Symbol | Yes | Date/datetime column name |
| `type` | Symbol | Yes | Data type (`:date` or `:datetime`) |
| `expression` | Proc | No | Custom Arel expression instead of column |
| `scope_proc` | Proc | No | Modifies the ActiveRecord scope |
| `parameters` | Hash | No | Parameter configuration (see below) |
| `description` | String | No | Human-readable description |

**Supported Parameters:**

| Parameter | Type | Values | Default | Description |
|-----------|------|--------|---------|-------------|
| `granularity` | String | `daily`, `weekly`, `monthly`, `yearly` | `monthly` | Time interval for grouping |

#### `exact_match` filter

Filters rows by exact value match using `WHERE column IN (...)`.

| Option | Type | Required | Description |
|--------|------|----------|-------------|
| `name` | Symbol | Yes | Column name to filter |
| `type` | Symbol | Yes | Data type of filter values |
| `expression` | Proc | No | Custom Arel expression instead of column |
| `max_size` | Integer | No | Maximum number of values allowed in filter |
| `description` | String | No | Human-readable description |

## Defining ClickHouse Engine

The ClickHouse engine (`Gitlab::Database::Aggregation::ClickHouse::Engine`) generates optimized queries for ClickHouse's columnar database.

### Example ClickHouse Engine

```ruby
class SessionAnalyticsEngine < Gitlab::Database::Aggregation::ClickHouse::Engine
  self.table_name = 'sessions'
  self.table_primary_key = %i[user_id session_id] # must match table primary key.

  filters do
    exact_match :flow_type, :string, description: 'Filter by flow type'
    range :created_at, :datetime, description: 'Filter by creation date'
  end

  dimensions do
    column :flow_type, :string, description: 'Group by flow type'
    date_bucket :created_at, :datetime,
      parameters: { granularity: { in: %i[daily weekly monthly], type: :string } },
      description: 'Group by date'
  end

  metrics do
    count description: 'Total sessions'
    count :completed, :integer,
      expression: -> { Arel.sql('1') },
      if: -> { Arel.sql('finished_at IS NOT NULL') },
      description: 'Completed sessions'
    mean :duration, :float,
      expression: -> { Arel.sql('finished_at - created_at') },
      if: -> { Arel.sql('finished_at IS NOT NULL') },
      description: 'Average session duration'
    rate :completion,
      numerator_if: -> { Arel.sql('finished_at IS NOT NULL') },
      description: 'Session completion rate'
    quantile :duration, :float,
      expression: -> { Arel.sql('finished_at - created_at') },
      parameters: { quantile: { type: :float, description: 'Quantile value (0.0-1.0)' } },
      description: 'Duration percentile'
  end
end
```

The ClickHouse engine generates a two-level nested query for optimal performance. Overall structure can be expressed like this:

```sql
-- metacode query to emphasize on query structure
SELECT dimensions, metrics
FROM (
  SELECT
    primary_key_columns,
    dimensions_expressions,
    metrics_expressions,
  FROM source_table
  WHERE filters
  GROUP BY ALL
) ch_aggregation_inner_query
GROUP BY ALL
ORDER BY orders
```

Inner query precalculates data for each primary key in source table. Outer query calculates metrics and dimensions based on inner query.

Example full query:

```sql
SELECT
  `ch_aggregation_inner_query`.`aeq_flow_type` AS aeq_flow_type,
  toStartOfInterval(
    `ch_aggregation_inner_query`.`aeq_created_at`,
    INTERVAL 1 month
  ) AS aeq_created_at,
  COUNT(*) AS aeq_total_count,
  countIf(`ch_aggregation_inner_query`.`aeq_completed_secondary` = 1) AS aeq_completed_count,
  avgIf(
    `ch_aggregation_inner_query`.`aeq_mean_duration`,
    `ch_aggregation_inner_query`.`aeq_mean_duration_secondary` = 1
  ) AS aeq_mean_duration,
  countIf(`ch_aggregation_inner_query`.`aeq_completion_rate` = 1) / COUNT(*) AS aeq_completion_rate,
  quantile(0.5)(`ch_aggregation_inner_query`.`aeq_duration_quantile`) AS aeq_duration_quantile
FROM (
  SELECT
    `sessions`.`flow_type` AS aeq_flow_type,
    `sessions`.`created_at` AS aeq_created_at,
    finished_at IS NOT NULL AS aeq_completed_secondary,
    finished_at - created_at AS aeq_mean_duration,
    finished_at IS NOT NULL AS aeq_mean_duration_secondary,
    finished_at IS NOT NULL AS aeq_completion_rate,
    finished_at - created_at AS aeq_duration_quantile,
    `sessions`.`user_id`,
    `sessions`.`session_id`
  FROM `sessions`
  WHERE `sessions`.`created_at` BETWEEN '2024-01-01' AND '2024-12-31'
  GROUP BY ALL
) ch_aggregation_inner_query
GROUP BY ALL
ORDER BY aeq_flow_type, aeq_created_at
```

Key characteristics:

- Two-level query structure (inner query + outer aggregation)
- Inner query handles row-level calculations and primary key grouping. Outer query performs final aggregations. This approach allows to use `*Merge` columns easily as well as `*If` aggregations.
- Conditional metrics use `*If` functions
- All columns are prefixed with `aeq_` (Aggregation Engine Query). This prefix is removed by `AggregationResult` object.
- Filters are applied as `WHERE` or `HAVING` clauses on **inner query**
- Dimensions become `GROUP BY` columns on **outer query**
- Metrics use aggregate functions on **outer query**

### Available Components

#### `count` metric

Counts rows with support for distinct counting and conditional counting using `countIf()`.

| Option | Type | Required | Description |
|--------|------|----------|-------------|
| `name` | Symbol | No | Name for the count metric. Default: `'total'`. Identifier becomes `:{name}_count` |
| `type` | Symbol | No | Data type. Default: `:integer` |
| `expression` | Proc | No | Custom expression for counting specific values |
| `if` | Proc | No | Condition expression for conditional counting (`countIf`) |
| `distinct` | Boolean | No | Enable distinct counting. Default: `false` |
| `formatter` | Proc | No | Formatting function applied to results |
| `description` | String | No | Human-readable description |

#### `mean` metric

Calculates the average value with support for conditional averaging using `avgIf()`.

| Option | Type | Required | Description |
|--------|------|----------|-------------|
| `name` | Symbol | Yes | Column name or identifier. Identifier becomes `:mean_{name}` |
| `type` | Symbol | No | Data type. Default: `:float` |
| `expression` | Proc | No | Custom expression for the value to average |
| `if` | Proc | No | Condition expression for conditional averaging (`avgIf`) |
| `formatter` | Proc | No | Formatting function applied to results |
| `description` | String | No | Human-readable description |

#### `rate` metric

Calculates the ratio between rows matching a numerator condition and rows matching a denominator condition (or total rows).

| Option | Type | Required | Description |
|--------|------|----------|-------------|
| `name` | Symbol | Yes | Identifier name. Identifier becomes `:{name}_rate` |
| `type` | Symbol | No | Data type. Default: `:float` |
| `numerator_if` | Proc | Yes | Condition for the numerator (rows to count) |
| `denominator_if` | Proc | No | Condition for the denominator. If not provided, uses total count |
| `formatter` | Proc | No | Formatting function applied to results |
| `description` | String | No | Human-readable description |

#### `quantile` metric

Calculates percentiles using ClickHouse's `quantile()` function. **Supports parameters.**

| Option | Type | Required | Description |
|--------|------|----------|-------------|
| `name` | Symbol | Yes | Column name or identifier. Identifier becomes `:{name}_quantile` |
| `type` | Symbol | No | Data type. Default: `:float` |
| `expression` | Proc | No | Custom expression for the value |
| `parameters` | Hash | No | Parameter configuration (see below) |
| `formatter` | Proc | No | Formatting function applied to results |
| `description` | String | No | Human-readable description |

**Supported Parameters:**

| Parameter | Type | Values | Default | Description |
|-----------|------|--------|---------|-------------|
| `quantile` | Float | `0.0` - `1.0` | `0.5` | Quantile value (0.5 = median, 0.9 = p90, 0.99 = p99) |

#### `column` dimension

Groups results by a column value.

| Option | Type | Required | Description |
|--------|------|----------|-------------|
| `name` | Symbol | Yes | Column name or identifier |
| `type` | Symbol | Yes | Data type (`:string`, `:integer`, `:datetime`, etc.) |
| `expression` | Proc | No | Custom expression instead of column |
| `formatter` | Proc | No | Formatting function applied to results |
| `description` | String | No | Human-readable description |

#### `date_bucket` dimension

Groups results by time intervals using ClickHouse's `toStartOfInterval()` function. **Supports parameters.**

| Option | Type | Required | Description |
|--------|------|----------|-------------|
| `name` | Symbol | Yes | Date/datetime column name |
| `type` | Symbol | Yes | Data type (`:date` or `:datetime`) |
| `expression` | Proc | No | Custom expression instead of column |
| `parameters` | Hash | No | Parameter configuration (see below) |
| `description` | String | No | Human-readable description |

**Supported Parameters:**

| Parameter | Type | Values | Default | Description |
|-----------|------|--------|---------|-------------|
| `granularity` | String | `daily`, `weekly`, `monthly`, `yearly` | `monthly` | Time interval for grouping |

#### `exact_match` filter

Filters rows by exact value match. Supports filtering on regular columns or merge columns (pre-aggregated data).

| Option | Type | Required | Description |
|--------|------|----------|-------------|
| `name` | Symbol | Yes | Column name to filter |
| `type` | Symbol | Yes | Data type of filter values |
| `expression` | Proc | No | Custom expression instead of column |
| `merge_column` | Boolean | No | If `true`, applies filter using `HAVING` instead of `WHERE` |
| `max_size` | Integer | No | Maximum number of values allowed in filter |
| `description` | String | No | Human-readable description |

#### `range` filter

Filters rows by value range using `BETWEEN`. Supports filtering on regular columns or merge columns.

| Option | Type | Required | Description |
|--------|------|----------|-------------|
| `name` | Symbol | Yes | Column name to filter |
| `type` | Symbol | Yes | Data type of filter values (`:datetime`, `:integer`, etc.) |
| `expression` | Proc | No | Custom expression instead of column |
| `merge_column` | Boolean | No | If `true`, applies filter using `HAVING` instead of `WHERE` |
| `description` | String | No | Human-readable description |

## Using the Framework

### Creating an aggregation request

```ruby
request = Gitlab::Database::Aggregation::Request.new(
  filters: [
    { identifier: :project_id, values: [1, 2, 3] },
    { identifier: :state, values: ['opened'] }
  ],
  dimensions: [
    { identifier: :author_id },
    { identifier: :created_at, parameters: { granularity: 'monthly' } },
    { identifier: :created_at, parameters: { granularity: 'weekly' } },
  ],
  metrics: [
    { identifier: :total_count },
    { identifier: :mean_weight }
  ],
  order: [
    { identifier: :total_count, direction: :desc } # order identifier must reference dimension or metric.
  ]
)
```

### Executing the request with the engine

```ruby
engine = IssueAggregationEngine.new(context: { scope: Issue.all })
response = engine.execute(request)

if response.success?
  puts "Success: #{response.payload[:data].to_a.inspect}"
else
  puts "Errors: #{response.errors}"
end
```

- Engine must be provided with base scope. Depending on your use case you might want to provide already prefiltered scope to current project, namespace, user etc.
- All request filters will be applied on provided base scope.

## Architecture Overview

The framework consists of several key components:

- **Engine**: The core class that defines available metrics, dimensions, and filters for a specific data source
- **Request**: Represents a query request with selected metrics, dimensions, filters, and ordering
- **QueryPlan**: Validates and transforms a request into executable query parts
- **AggregationResult**: Handles query execution and result formatting

```chart
┌────────────────────────────────────────────────────┐
│                        Request                     │
│  (metrics, dimensions, filters, order)             │
└────────────────────────────────────────────────────┘
                            │
                            ▼
┌────────────────────────────────────────────────────┐
│                        QueryPlan                   │
│  (validates request, builds plan parts)            │
└────────────────────────────────────────────────────┘
                            │
                            ▼
┌────────────────────────────────────────────────────┐
│                         Engine                     │
│  (executes query plan, returns AggregationResult)  │
└────────────────────────────────────────────────────┘
                            │
                            ▼
┌────────────────────────────────────────────────────┐
│                   AggregationResult                │
│ implements Enumerable to access formatted results  │
└────────────────────────────────────────────────────┘
```

## Validation

The framework validates requests before execution:

- At least one metric is required
- All referenced identifiers must exist in the engine definition
- Parameters must fit their declared validations. E.g. `granularity: { in: %i[daily weekly monthly], type: :string }` will require granularity value to be one of 3 provided strings.

## GraphQL Integration

The Aggregation Framework provides seamless GraphQL integration through the `Mounter` module. See [GraphQL Integration](aggregation_framework_graphql.md) for detailed documentation.

## Related Documentation

- [Aggregation engine GraphQL Integration](aggregation_framework_graphql.md)
- [ClickHouse Development](clickhouse/_index.md)
