---
stage: Foundations
group: Import and Integrate
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: GraphQL pagination
---

## Types of pagination

GitLab uses two primary types of pagination: **offset** and **keyset**
(sometimes called cursor-based) pagination.
The GraphQL API mainly uses keyset pagination, falling back to offset pagination when needed.

### Performance considerations

See the [general pagination guidelines section](../database/pagination_guidelines.md) for more information.

### Offset pagination

This is the traditional, page-by-page pagination, that is most common,
and used across much of GitLab. You can recognize it by
a list of page numbers near the bottom of a page, which, when selected,
take you to that page of results.

For example, when you select **Page 100**, we send `100` to the
backend. For example, if each page has say 20 items, the
backend calculates `20 * 100 = 2000`,
and it queries the database by offsetting (skipping) the first 2000
records and pulls the next 20.

```plaintext
page number * page size = where to find my records
```

There are a couple of problems with this:

- Performance. When we query for page 100 (which gives an offset of
  2000), then the database has to scan through the table to that
  specific offset, and then pick up the next 20 records. As the offset
  increases, the performance degrades quickly.
  Read more in
  [The SQL I Love <3. Efficient pagination of a table with 100M records](http://allyouneedisbackend.com/blog/2017/09/24/the-sql-i-love-part-1-scanning-large-table/).

- Data stability. When you get the 20 items for page 100 (at
  offset 2000), GitLab shows those 20 items. If someone then
  deletes or adds records in page 99 or before, the items at
  offset 2000 become a different set of items. You can even get into a
  situation where, when paginating, you could skip over items,
  because the list keeps changing.
  Read more in
  [Pagination: You're (Probably) Doing It Wrong](https://coderwall.com/p/lkcaag/pagination-you-re-probably-doing-it-wrong).

### Keyset pagination

Given any specific record, if you know how to calculate what comes
after it, you can query the database for those specific records.

For example, suppose you have a list of issues sorted by creation date.
If you know the first item on a page has a specific date (say Jan 1), you can ask
for all records that were created after that date and take the first 20.
It no longer matters if many are deleted or added, as you always ask for
the ones after that date, and so get the correct items.

Unfortunately, there is no easy way to know if the issue created
on Jan 1 is on page 20 or page 100.

Some of the benefits and tradeoffs of keyset pagination are

- Performance is much better.

- More data stability for end-users since records are not missing from lists due to
  deletions or insertions.

- It's the best way to do infinite scrolling.

- It's more difficult to program and maintain. Easy for `updated_at` and
  `sort_order`, complicated (or impossible) for [complex sorting scenarios](#query-complexity).

## Implementation

When pagination is supported for a query, GitLab defaults to using
keyset pagination. You can see where this is configured in
[`pagination/connections.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/graphql/pagination/connections.rb).
If a query returns `ActiveRecord::Relation`, keyset pagination is automatically used.

This was a conscious decision to support performance and data stability.

However, there are some cases where we have to use the offset
pagination connection, `OffsetActiveRecordRelationConnection`, such as when
sorting by label priority in issues, due to the complexity of the sort.

If you return a relation from a resolver that is not suitable for keyset
pagination (due to the sort order for example), then you can use the
`BaseResolver#offset_pagination` method to wrap the relation in the correct
connection type. For example:

```ruby
def resolve(**args)
  result = Finder.new(object, current_user, args).execute
  result = offset_pagination(result) if needs_offset?(args[:sort])

  result
end
```

### Keyset pagination

The keyset pagination implementation is a subclass of `GraphQL::Pagination::ActiveRecordRelationConnection`,
which is a part of the `graphql` gem. This is installed as the default for all `ActiveRecord::Relation`.
However, instead of using a cursor based on an offset (which is the default), GitLab uses a more specialized cursor.

The cursor is created by encoding a JSON object which contains the relevant ordering fields. For example:

```ruby
ordering = {"id"=>"72410125", "created_at"=>"2020-10-08 18:05:21.953398000 UTC"}
json = ordering.to_json
cursor = Base64.urlsafe_encode64(json, padding: false)

"eyJpZCI6IjcyNDEwMTI1IiwiY3JlYXRlZF9hdCI6IjIwMjAtMTAtMDggMTg6MDU6MjEuOTUzMzk4MDAwIFVUQyJ9"

json = Base64.urlsafe_decode64(cursor)
Gitlab::Json.parse(json)

{"id"=>"72410125", "created_at"=>"2020-10-08 18:05:21.953398000 UTC"}
```

The benefits of storing the order attribute values in the cursor:

- If only the ID of the object were stored, the object and its attributes could be queried.
  That would require an additional query, and if the object is no longer there, then the needed
  attributes are not available.
- If an attribute is `NULL`, then one SQL query can be used. If it's not `NULL`, then a
  different SQL query can be used.

Based on whether the main attribute field being sorted on is `NULL` in the cursor, the proper query
condition is built. The last ordering field is considered to be unique (a primary key), meaning the
column never contains `NULL` values.

#### Query complexity

We only support two ordering fields, and one of those fields needs to be the primary key.

Here are two examples of pseudocode for the query:

- **Two-condition query.** `X` represents the values from the cursor. `C` represents
  the columns in the database, sorted in ascending order, using an `:after` cursor, and with `NULL`
  values sorted last.

  ```plaintext
  X1 IS NOT NULL
    AND
      (C1 > X1)
        OR
      (C1 IS NULL)
        OR
      (C1 = X1
        AND
       C2 > X2)

  X1 IS NULL
    AND
      (C1 IS NULL
        AND
       C2 > X2)
  ```

  Below is an example based on the relation `Issue.order(relative_position: :asc).order(id: :asc)`
  with an after cursor of `relative_position: 1500, id: 500`:

  ```plaintext
  when cursor[relative_position] is not NULL

      ("issues"."relative_position" > 1500)
      OR (
        "issues"."relative_position" = 1500
        AND
        "issues"."id" > 500
      )
      OR ("issues"."relative_position" IS NULL)

  when cursor[relative_position] is NULL

      "issues"."relative_position" IS NULL
      AND
      "issues"."id" > 500
  ```

- **Three-condition query.** The example below is not complete, but shows the
  complexity of adding one more condition. `X` represents the values from the cursor. `C` represents
  the columns in the database, sorted in ascending order, using an `:after` cursor, and with `NULL`
  values sorted last.

  ```plaintext
  X1 IS NOT NULL
    AND
      (C1 > X1)
        OR
      (C1 IS NULL)
        OR
      (C1 = X1 AND C2 > X2)
        OR
      (C1 = X1
        AND
          X2 IS NOT NULL
            AND
              ((C2 > X2)
                 OR
               (C2 IS NULL)
                 OR
               (C2 = X2 AND C3 > X3)
        OR
          X2 IS NULL.....
  ```

By using
[`Gitlab::Graphql::Pagination::Keyset::QueryBuilder`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/graphql/pagination/keyset/query_builder.rb),
we're able to build the necessary SQL conditions and apply them to the Active Record relation.

Complex queries can be difficult or impossible to use. For example,
in [`issuable.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/models/concerns/issuable.rb),
the `order_due_date_and_labels_priority` method creates a very complex query.

These types of queries are not supported. In these instances, you can use offset pagination.

#### Gotchas

Do not define a collection's order using the string syntax:

```ruby
# Bad
items.order('created_at DESC')
```

Instead, use the hash syntax:

```ruby
# Good
items.order(created_at: :desc)
```

The first example won't correctly embed the sort information (`created_at`, in
the example above) into the pagination cursors, which will result in an
incorrect sort order.

### Offset pagination

There are times when the [complexity of sorting](#query-complexity)
is more than our keyset pagination can handle.

For example, in [`ProjectIssuesResolver`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/graphql/resolvers/project_issues_resolver.rb),
when sorting by `priority_asc`, we can't use keyset pagination as the ordering is much
too complex. For more information, read [`issuable.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/models/concerns/issuable.rb).

In cases like this, we can fall back to regular offset pagination by returning a
[`Gitlab::Graphql::Pagination::OffsetActiveRecordRelationConnection`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/graphql/pagination/offset_active_record_relation_connection.rb)
instead of an `ActiveRecord::Relation`:

```ruby
    def resolve(parent, finder, **args)
      issues = apply_lookahead(Gitlab::Graphql::Loaders::IssuableLoader.new(parent, finder).batching_find_all)

      if non_stable_cursor_sort?(args[:sort])
        # Certain complex sorts are not supported by the stable cursor pagination yet.
        # In these cases, we use offset pagination, so we return the correct connection.
        offset_pagination(issues)
      else
        issues
      end
    end
```

<!-- ### External pagination -->

### External pagination

There may be times where you need to return data through the GitLab API that is stored in
another system. In these cases you may have to paginate a third-party's API.

An example of this is with our [Error Tracking](../../operations/error_tracking.md) implementation,
where we proxy [Sentry errors](../../operations/sentry_error_tracking.md) through
the GitLab API. We do this by calling the Sentry API which enforces its own pagination rules.
This means we cannot access the collection within GitLab to perform our own custom pagination.

For consistency, we manually set the pagination cursors based on values returned by the external API, using `Gitlab::Graphql::ExternallyPaginatedArray.new(previous_cursor, next_cursor, *items)`.

You can see an example implementation in the following files:

- [`types/error__tracking/sentry_error_collection_type.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/graphql/types/error_tracking/sentry_error_collection_type.rb) which adds an extension to `field :errors`.
- [`resolvers/error_tracking/sentry_errors_resolver.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/graphql/resolvers/error_tracking/sentry_errors_resolver.rb) which returns the data from the resolver.

## Testing

Any GraphQL field that supports pagination and sorting should be tested
using the sorted paginated query shared example found in
[`graphql/sorted_paginated_query_shared_examples.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/spec/support/shared_examples/graphql/sorted_paginated_query_shared_examples.rb).
It helps verify that your sort keys are compatible and that cursors
work properly.

This is particularly important when using keyset pagination, as some sort keys might not be supported.

Add a section to your request specs like this:

```ruby
describe 'sorting and pagination' do
  ...
end
```

You can then use
[`issues_spec.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/spec/requests/api/graphql/project/issues_spec.rb)
as an example to construct your tests.

[`graphql/sorted_paginated_query_shared_examples.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/spec/support/shared_examples/graphql/sorted_paginated_query_shared_examples.rb)
also contains some documentation on how to use the shared examples.

The shared example requires certain `let` variables and methods to be set up:

```ruby
describe 'sorting and pagination' do
  let_it_be(:sort_project) { create(:project, :public) }
  let(:data_path)    { [:project, :issues] }

  def pagination_query(params)
    graphql_query_for( :project, { full_path: sort_project.full_path },
      query_nodes(:issues, :id, include_pagination_info: true, args: params))
    )
  end

  def pagination_results_data(nodes)
    nodes.map { |issue| issue['iid'].to_i }
  end

  context 'when sorting by weight' do
    let_it_be(:issues) { make_some_issues_with_weights }

    context 'when ascending' do
      let(:ordered_issues) { issues.sort_by(&:weight) }

      it_behaves_like 'sorted paginated query' do
        let(:sort_param) { :WEIGHT_ASC }
        let(:first_param) { 2 }
        let(:all_records) { ordered_issues.map(&:iid) }
      end
    end
  end
```
