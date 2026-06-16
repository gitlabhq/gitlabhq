---
stage: Analytics
group: Optimize
info: Any user with at least the Maintainer role can merge updates to this content. For details, see <https://docs.gitlab.com/development/development_processes/#development-guidelines-review>.
title: Aggregation engines
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
| `scope_proc` | Proc | No | Modifies the ActiveRecord scope (for example for JOINs) |
| `formatter` | Proc | No | Formatting function applied to results |
| `description` | String | No | Human-readable description |

#### `column` dimension

Groups results by a column value.

| Option | Type | Required | Description |
|--------|------|----------|-------------|
| `name` | Symbol | Yes | Column name or identifier |
| `type` | Symbol | Yes | Data type (`:string`, `:integer`, `:datetime`, etc.) |
| `expression` | Proc | No | Custom Arel expression instead of column |
| `scope_proc` | Proc | No | Modifies the ActiveRecord scope (for example for JOINs) |
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
- Column filters are applied as `WHERE` or `HAVING` clauses on the **inner query**
- Metric filters are applied as `HAVING` clauses on the **outer query**
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

#### `retained_count` metric

Counts values that appear in both the current and previous period, using `groupBitmapState`
and `arrayIntersect`. Use `retained_count` for feature retention or returning-user counts.
The dimension referenced by `over:` must be requested in the query.

| Option | Type | Required | Description |
|--------|------|----------|-------------|
| `name` | Symbol | Yes | Identifier name. Identifier becomes `:{name}_count` |
| `type` | Symbol | No | Data type. Default: `:integer` |
| `expression` | Proc | No | Expression for the value to deduplicate, for example `user_id` |
| `over` | Symbol | Yes | Dimension that defines the period. Must be a dimension on the engine |
| `lag_offset` | Integer | No | Number of periods to compare against. Default: `1` |
| `description` | String | No | Human-readable description |

Example:

```ruby
metrics do
  retained_count :returning_users, :integer, -> { sql('user_id') }, over: :timestamp,
    description: 'Users present in both the current and previous period'
end
```

#### `lagged_count` metric

Returns the distinct count of values from the previous period, using `uniqExact` with
`lagInFrame`. Pair `lagged_count` with `retained_count` to compute retention rates
(returning ÷ previous). The dimension referenced by `over:` must be requested in the query.

| Option | Type | Required | Description |
|--------|------|----------|-------------|
| `name` | Symbol | Yes | Identifier name. Identifier becomes `:{name}_count` |
| `type` | Symbol | No | Data type. Default: `:integer` |
| `expression` | Proc | No | Expression for the value to deduplicate |
| `over` | Symbol | Yes | Dimension that defines the period |
| `lag_offset` | Integer | No | Number of periods to look back. Default: `1` |
| `description` | String | No | Human-readable description |

Example:

```ruby
metrics do
  lagged_count :previous_period_users, :integer, -> { sql('user_id') }, over: :timestamp,
    description: 'Distinct users in the previous period'
end
```

When a request includes more dimensions than just `over:`, the framework partitions the
lag window by the extra dimensions. Each combination gets an independent sequence, so
values do not leak across categories. For example, with `dimensions: [feature, timestamp]`
where `timestamp` is a `date_bucket` with `granularity: 'daily'` and the metric uses
`over: :timestamp`, the generated SQL contains
`OVER (PARTITION BY aeq_feature ORDER BY aeq_timestamp_daily ASC)`. Retention for
`code_suggestions` does not mix with `chat`.

#### `column` dimension

Groups results by a column value.

| Option | Type | Required | Description |
|--------|------|----------|-------------|
| `name` | Symbol | Yes | Column name or identifier |
| `type` | Symbol | Yes | Data type (`:string`, `:integer`, `:datetime`, etc.) |
| `expression` | Proc | No | Custom expression instead of column |
| `formatter` | Proc | No | Formatting function applied to results |
| `description` | String | No | Human-readable description |
| `association` | Boolean | No | When `true`, the dimension is also accessible without the `_id` suffix as an object. Defaults to `false`. |

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

#### `metric_exact_match` filter

Filters groups by exact match on an aggregated metric value. Applied as a `HAVING` clause in post-aggregation.

| Option | Type | Required | Description |
|--------|------|----------|-------------|
| `name` | Symbol | Yes | Identifier of the metric to filter by. Must match a metric defined in the same engine. |
| `type` | Symbol | Yes | Data type of filter values |
| `max_size` | Integer | No | Maximum number of values allowed in filter |
| `description` | String | No | Human-readable description |

The referenced metric must also be requested in the same `Request`. For parameterized metrics,
the filter `parameters` must match the parameters of the requested metric instance.

Example:

```ruby
filters do
  metric_exact_match :total_count, :integer
end
```

```ruby
Gitlab::Database::Aggregation::Request.new(
  filters: [{ identifier: :total_count, values: [1, 2] }],
  dimensions: [{ identifier: :user_id }],
  metrics: [{ identifier: :total_count }]
)
```

#### `metric_range` filter

Filters groups by value range on an aggregated metric using `BETWEEN`. Applied as a `HAVING`
clause in post-aggregation.

| Option | Type | Required | Description |
|--------|------|----------|-------------|
| `name` | Symbol | Yes | Identifier of the metric to filter by. Must match a metric defined in the same engine. |
| `type` | Symbol | Yes | Data type of filter values (`:integer`, `:float`, etc.) |
| `description` | String | No | Human-readable description |

The referenced metric must also be requested in the same `Request`. For parameterized metrics,
the filter `parameters` must match the parameters of the requested metric instance, so the filter
targets the correct metric instance.

Example:

```ruby
filters do
  metric_range :total_count, :integer
  metric_range :duration_quantile, :float
end
```

```ruby
Gitlab::Database::Aggregation::Request.new(
  filters: [
    { identifier: :duration_quantile, parameters: { quantile: 0.1 }, values: 200..nil }
  ],
  dimensions: [{ identifier: :user_id }],
  metrics: [{ identifier: :duration_quantile, parameters: { quantile: 0.1 } }]
)
```

## Transient columns

Transient columns are named SQL expression aliases you define once and
reference across `dimensions`, `metrics`, and `filters` blocks. They are
not projected in the final query result. Use transient columns to
eliminate duplication of complex SQL expressions.

### Define a transient column

Call `transient` at the class level with a name and a block that returns
an Arel expression. Define transient columns before you reference them.

```ruby
transient(:duration) do
  sql("dateDiff('seconds', anyIfMerge(created_event_at), anyIfMerge(finished_event_at))")
end

transient(:is_finished) { sql('anyIfMerge(finished_event_at) IS NOT NULL') }
```

### Reference a transient column

Inside `dimensions`, `metrics`, or `filters` blocks, call
`transient(:name)` to insert the stored expression. Pass the return
value anywhere a lambda expression is accepted: as a positional
argument or as a keyword argument value.

```ruby
metrics do
  mean :duration, :float, transient(:duration),
    description: 'Average session duration in seconds'

  count :finished, if: transient(:is_finished),
    description: 'Number of finished sessions'
end
```

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

## Architecture overview

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

## GraphQL integration

Use the `Gitlab::Database::Aggregation::Graphql::Mounter` module to expose aggregation engines
in the GraphQL API.

The GraphQL integration automatically generates:

- **Query field** for mounted engine
- **Filter arguments** based on engine filter definitions
- **Order argument** based on engine dimensions and metrics definitions. Snake-cased dimension and metric identifiers can be used as an order identifier
- **Response types** with dimensions and metrics as fields
- **Parameterized fields** for dimensions and metrics with parameters
- **Pagination**: aggregation results are automatically paginated using `OFFSET` pagination

### Mounting an engine

Use the `mount_aggregation_engine` method in your GraphQL type to expose an aggregation engine:

```ruby
module Types
  class ProjectType < BaseObject
    extend Gitlab::Database::Aggregation::Graphql::Mounter

    mount_aggregation_engine(
      IssueAggregationEngine,
      field_name: 'issue_analytics',
      description: 'Issue analytics aggregation'
    ) do
      # Define base aggregation scope. Build your own scope or inherit one from parent object.
      def aggregation_scope
        object.issues
      end
    end
  end
end
```

> [!note]
> All filters, metrics, and dimensions are exposed automatically.

### Mounter options

| Option | Type | Description |
|--------|------|-------------|
| `field_name` | String/Symbol | The GraphQL field name. Defaults to `:aggregation` |
| `types_prefix` | String/Symbol | Prefix for all child types like `*AggregationResponse`. Defaults to `field_name` |
| `description` | String | Description for the GraphQL field |
| `authorize` | Symbol | Permission required to access the field (e.g. `:read_project`). Passed directly to the GraphQL field definition |

### Authorization

Use the `authorize` option to restrict access to the field:

```ruby
mount_aggregation_engine(
  IssueAggregationEngine,
  field_name: 'issue_analytics',
  description: 'Issue analytics aggregation',
  authorize: :read_project
) do
  # authorize :read_project - this also supported.
  def aggregation_scope
    object.issues
  end
end
```

If `authorize` is not specified, you must take care of authorization manually.

### Example GraphQL query

The generated GraphQL subtree uses a two-level structure:

- The outer field (`issueAnalytics`) accepts **dimension and non-metric filter** arguments.
- The inner `aggregated` field accepts **metric filter**, **ordering**, and **pagination** arguments,
  and returns the paginated connection.

```graphql
query IssueAnalytics($projectId: ID!) {
  project(fullPath: $projectId) {
    issueAnalytics(
      state: ["opened", "closed"]
      createdAtFrom: "2024-01-01"
      createdAtTo: "2024-12-31"
    ) {
      aggregated(
        totalCountFrom: 5
        orderBy: [{ identifier: "totalCount", direction: DESC }]
        first: 10
      ) {
        nodes {
          dimensions {
            createdAt(granularity: "monthly")
          }
          totalCount
          meanWeight
          highQuantile: durationQuantile(0.9)
          medianQuantile: durationQuantile(0.5)
        }
        pageInfo {
          hasNextPage
          endCursor
        }
      }
    }
  }
}
```

### Filter placement

Filter arguments are split across the two levels based on when the filter is applied:

- **Non-metric filters** (those defined with `exact_match` or `range`) appear on the outer field (e.g. `issueAnalytics`).
- **Metric filters** (those defined with `metric_exact_match` or `metric_range`) appear on the
  inner `aggregated` field.

### Custom request validations

Add custom validation logic to discard specific aggregation requests while maintaining the GraphQL
schema. This is useful when you need to enforce custom runtime constraints on specific requests.

Raise a `GraphQL::ExecutionError` to reject the request with a custom error message.

To add custom validations, override the `validate_request!` method in the mounting block:

```ruby
module Types
  class ProjectType < BaseObject
    extend Gitlab::Database::Aggregation::Graphql::Mounter

    mount_aggregation_engine(IssueAggregationEngine) do
      # Other configuration options...
      # Custom validation logic
      def validate_request!(engine_request)
        if engine_request.dimensions.empty?
          raise GraphQL::ExecutionError, 'At least one dimension must be specified'
        end
      end
    end
  end
end
```

The `validate_request!` method receives a `Gitlab::Database::Aggregation::Request` object containing `dimensions`, `metrics`, `filters` and `order` specifications.

### Dimensions for ActiveRecord association

Dimensions can be marked as associations using the `association: true` option. This changes how the dimension is exposed in GraphQL, automatically resolving the associated model instead of exposing just the ID.

#### Defining association dimensions

In your aggregation engine, declare a dimension with `association: true`:

```ruby
class AgentPlatformSessions < Gitlab::Database::Aggregation::ClickHouse::Engine
  dimensions do
    column :flow_type, :string, description: 'Type of session'
    column :user_id, :integer, description: 'Session owner', association: true
  end
end
```

#### GraphQL schema impact

When a dimension is marked as an association, an object is exposed instead of the raw `*_id` field. The dimension above transforms to `field :user, Types::UserType, ...` in GraphQL with batch loading by ID.
You can order the dimensions by the association ID using the association name without `_id` suffix (for example, `orderBy: [{ identifier: "user", direction: DESC }]`).

> [!note]
> You must ensure all proper authorization checks on association GraphQL type (e.g. `authorize :read_user`).

#### Custom association configuration

By default, the association model and GraphQL type are inferred from the dimension name:

- Model: `user_id` → `User`
- GraphQL type: `User` → `Types::UserType`

You can customize this behavior by passing a hash to the `association` option:

```ruby
dimensions do
  column :author_id, :integer,
    description: 'Issue author',
    association: { model: User }
    # or model and GraphQL type
    # association: { model: User, graphql_type: Types::CurrentUserType }
end
```

#### GraphQL query examples

The following example is a query without association:

```graphql
query {
  project(fullPath: "gitlab-org/gitlab") {
    aiUsage {
      agentPlatformSessions {
        aggregated {
          nodes {
            dimensions {
              userId  # Returns: 123 (integer)
            }
          }
        }
      }
    }
  }
}
```

The following example is a query with association:

```graphql
query {
  project(fullPath: "gitlab-org/gitlab") {
    aiUsage {
      agentPlatformSessions(
        userId: [1, 2]  # Filter still uses original dimension identifier
      ) {
        aggregated(
          orderBy: [{ identifier: "user", direction: DESC }]  # Order uses association name
        ) {
          nodes {
            dimensions {
              user {  # Returns: full User object
                id
                username
                name
              }
            }
          }
        }
      }
    }
  }
}
```

## Related documentation

- [ClickHouse development](database/clickhouse/_index.md)
- [GraphQL API style guide](api_graphql_styleguide.md)
