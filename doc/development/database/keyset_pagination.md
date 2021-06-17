---
stage: Enablement
group: Database
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Keyset pagination

The keyset pagination library can be used in HAML-based views and the REST API within the GitLab project.

You can read about keyset pagination and how it compares to the offset based pagination on our [pagination guidelines](pagination_guidelines.md) page.

## API overview

### Synopsis

Keyset pagination with `ActiveRecord` in Rails controllers:

```ruby
cursor = params[:cursor] # this is nil when the first page is requested
paginator = Project.order(:created_at).keyset_paginate(cursor: cursor, per_page: 20)

paginator.each do |project|
  puts project.name # prints maximum 20 projects
end
```

### Usage

This library adds a single method to ActiveRecord relations: [`#keyset_paginate`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/config/initializers/active_record_keyset_pagination.rb).

This is similar in spirit (but not in implementation) to Kaminari's `paginate` method.

Keyset pagination works without any configuration for simple ActiveRecord queries:

- Order by one column.
- Order by two columns, where the last column is the primary key.

The library can detect nullable and non-distinct columns and based on these, it will add extra ordering using the primary key. This is necessary because keyset pagination expects distinct order by values:

```ruby
Project.order(:created_at).keyset_paginate.records # ORDER BY created_at, id

Project.order(:name).keyset_paginate.records # ORDER BY name, id

Project.order(:created_at, id: :desc).keyset_paginate.records # ORDER BY created_at, id

Project.order(created_at: :asc, id: :desc).keyset_paginate.records # ORDER BY created_at, id  DESC
```

The `keyset_paginate` method returns [a special paginator object](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/pagination/keyset/paginator.rb) which contains the loaded records and additional information for requesting various pages.

The method accepts the following keyword arguments:

- `cursor` - Encoded order by column values for requesting the next page (can be `nil`).
- `per_page` - Number of records to load per page (default 20).
- `keyset_order_options` - Extra options for building the keyset paginated database query, see an example for `UNION` queries in the performance section (optional).

The paginator object has the following methods:

- `records` - Returns the records for the current page.
- `has_next_page?` - Tells whether there is a next page.
- `has_previous_page?` - Tells whether there is a previous page.
- `cursor_for_next_page` - Encoded values as `String` for requesting the next page (can be `nil`).
- `cursor_for_previous_page` - Encoded values as `String` for requesting the previous page (can be `nil`).
- `cursor_for_first_page` - Encoded values as `String` for requesting the first page.
- `cursor_for_last_page` - Encoded values as `String` for requesting the last page.
- The paginator objects includes the `Enumerable` module and delegates the enumerable functionality to the `records` method/array.

Example for getting the first and the second page:

```ruby
paginator = Project.order(:name).keyset_paginate

paginator.to_a # same as .records

cursor = paginator.cursor_for_next_page # encoded column attributes for the next page

paginator = Project.order(:name).keyset_paginate(cursor: cursor).records # loading the next page
```

Since keyset pagination does not support page numbers, we are restricted to go to the following pages:

- Next page
- Previous page
- Last page
- First page

#### Usage in Rails with HAML views

Consider the following controller action, where we list the projects ordered by name:

```ruby
def index
  @projects = Project.order(:name).keyset_paginate(cursor: params[:cursor])
end
```

In the HAML file, we can render the records:

```ruby
- if @projects.any?
  - @projects.each do |project|
    .project-container
      = project.name

  = keyset_paginate @projects
```

## Performance

The performance of the keyset pagination depends on the database index configuration and the number of columns we use in the `ORDER BY` clause.

In case we order by the primary key (`id`), then the generated queries will be efficient since the primary key is covered by a database index.

When two or more columns are used in the `ORDER BY` clause, it's advised to check the generated database query and make sure that the correct index configuration is used. More information can be found on the [pagination guideline page](pagination_guidelines.md#index-coverage).

NOTE:
While the query performance of the first page might look good, the second page (where the cursor attributes are used in the query) might yield poor performance. It's advised to always verify the performance of both queries: first page and second page.

Example database query with tie-breaker (`id`) column:

```sql
SELECT "issues".*
FROM "issues"
WHERE (("issues"."id" > 99
      AND "issues"."created_at" = '2021-02-16 11:26:17.408466')
    OR ("issues"."created_at" > '2021-02-16 11:26:17.408466')
    OR ("issues"."created_at" IS NULL))
ORDER BY "issues"."created_at" DESC NULLS LAST, "issues"."id" DESC
LIMIT 20
```

`OR` queries are difficult to optimize in PostgreSQL, we generally advise using [`UNION` queries](../sql.md#use-unions) instead. The keyset pagination library can generate efficient `UNION` when multiple columns are present in the `ORDER BY` clause. This is triggered when we specify the `use_union_optimization: true` option in the options passed to `Relation#keyset_paginate`.

Example:

```ruby
# Triggers a simple query for the first page.
paginator1 = Project.order(:created_at, id: :desc).keyset_paginate(per_page: 2, keyset_order_options: { use_union_optimization: true })

cursor = paginator1.cursor_for_next_page

# Triggers UNION query for the second page
paginator2 = Project.order(:created_at, id: :desc).keyset_paginate(per_page: 2, cursor: cursor, keyset_order_options: { use_union_optimization: true })

puts paginator2.records.to_a # UNION query
```

## Complex order configuration

Common `ORDER BY` configurations will be handled by the `keyset_paginate` method automatically so no manual configuration is needed. There are a few edge cases where order object configuration is necessary:

- `NULLS LAST` ordering.
- Function-based ordering.
- Ordering with a custom tie-breaker column, like `iid`.

These order objects can be defined in the model classes as normal ActiveRecord scopes, there is no special behavior that prevents using these scopes elsewhere (kaminari, background jobs).

### `NULLS LAST` ordering

Consider the following scope:

```ruby
scope = Issue.where(project_id: 10).order(Gitlab::Database.nulls_last_order('relative_position', 'DESC'))
# SELECT "issues".* FROM "issues" WHERE "issues"."project_id" = 10 ORDER BY relative_position DESC NULLS LAST

scope.keyset_paginate # raises: Gitlab::Pagination::Keyset::Paginator::UnsupportedScopeOrder: The order on the scope does not support keyset pagination
```

The `keyset_paginate` method raises an error because the order value on the query is a custom SQL string and not an [`Arel`](https://www.rubydoc.info/gems/arel) AST node. The keyset library cannot automatically infer configuration values from these kinds of queries.

To make keyset pagination work, we need to configure custom order objects, to do so, we need to collect information about the order columns:

- `relative_position` can have duplicated values since no unique index is present.
- `relative_position` can have null values because we don't have a not null constraint on the column. For this, we need to determine where will we see NULL values, at the beginning of the resultset or the end (`NULLS LAST`).
- Keyset pagination requires distinct order columns, so we'll need to add the primary key (`id`) to make the order distinct.
- Jumping to the last page and paginating backwards actually reverses the `ORDER BY` clause. For this, we'll need to provide the reversed `ORDER BY` clause.

Example:

```ruby
order = Gitlab::Pagination::Keyset::Order.build([
  # The attributes are documented in the `lib/gitlab/pagination/keyset/column_order_definition.rb` file
  Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
    attribute_name: 'relative_position',
    column_expression: Issue.arel_table[:relative_position],
    order_expression: Gitlab::Database.nulls_last_order('relative_position', 'DESC'),
    reversed_order_expression: Gitlab::Database.nulls_first_order('relative_position', 'ASC'),
    nullable: :nulls_last,
    order_direction: :desc,
    distinct: false
  ),
  Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
    attribute_name: 'id',
    order_expression: Issue.arel_table[:id].asc,
    nullable: :not_nullable,
    distinct: true
  )
])

scope = Issue.where(project_id: 10).order(order) # or reorder()

scope.keyset_paginate.records # works
```

### Function-based ordering

In the following example, we multiply the `id` by 10 and ordering by that value. Since the `id` column is unique, we need to define only one column:

```ruby
order = Gitlab::Pagination::Keyset::Order.build([
  Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
    attribute_name: 'id_times_ten',
    order_expression: Arel.sql('id * 10').asc,
    nullable: :not_nullable,
    order_direction: :asc,
    distinct: true,
    add_to_projections: true
  )
])

paginator = Issue.where(project_id: 10).order(order).keyset_paginate(per_page: 5)
puts paginator.records.map(&:id_times_ten)

cursor = paginator.cursor_for_next_page

paginator = Issue.where(project_id: 10).order(order).keyset_paginate(cursor: cursor, per_page: 5)
puts paginator.records.map(&:id_times_ten)
```

The `add_to_projections` flag tells the paginator to expose the column expression in the `SELECT` clause. This is necessary because the keyset pagination needs to somehow extract the last value from the records to request the next page.

### `iid` based ordering

When ordering issues, the database ensures that we'll have distinct `iid` values within a project. Ordering by one column is enough to make the pagination work if the `project_id` filter is present:

```ruby
order = Gitlab::Pagination::Keyset::Order.build([
  Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
    attribute_name: 'iid',
    order_expression: Issue.arel_table[:iid].asc,
    nullable: :not_nullable,
    distinct: true
  )
])

scope = Issue.where(project_id: 10).order(order)

scope.keyset_paginate.records # works
```
