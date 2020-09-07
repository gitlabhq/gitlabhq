# GraphQL pagination

## Types of pagination

GitLab uses two primary types of pagination: **offset** and **keyset**
(sometimes called cursor-based) pagination.
The GraphQL API mainly uses keyset pagination, falling back to offset pagination when needed.

### Offset pagination

This is the traditional, page-by-page pagination, that is most common,
and used across much of GitLab. You can recognize it by
a list of page numbers near the bottom of a page, which, when clicked,
take you to that page of results.

For example, when you click **Page 100**, we send `100` to the
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

- Data stability is greater since you're not going to miss records due to
  deletions or insertions.

- It's the best way to do infinite scrolling.

- It's more difficult to program and maintain. Easy for `updated_at` and
  `sort_order`, complicated (or impossible) for complex sorting scenarios.

## Implementation

When pagination is supported for a query, GitLab defaults to using
keyset pagination. You can see where this is configured in
[`pagination/connections.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/graphql/pagination/connections.rb).
If a query returns `ActiveRecord::Relation`, keyset pagination is automatically used.

This was a conscious decision to support performance and data stability.

However, there are some cases where we have to use the offset
pagination connection, `OffsetActiveRecordRelationConnection`, such as when
sorting by label priority in issues, due to the complexity of the sort.

<!-- ### Keyset pagination -->

<!-- ### Offset pagination -->

<!-- ### External pagination -->

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
  let(:sort_project) { create(:project, :public) }
  let(:data_path)    { [:project, :issues] }

  def pagination_query(params, page_info)
    graphql_query_for(
      'project',
      { 'fullPath' => sort_project.full_path },
      query_graphql_field('issues', params, "#{page_info} edges { node { id } }")
    )
  end

  def pagination_results_data(data)
    data.map { |issue| issue.dig('node', 'iid').to_i }
  end

  context 'when sorting by weight' do
    ...
    context 'when ascending' do
      it_behaves_like 'sorted paginated query' do
        let(:sort_param)       { 'WEIGHT_ASC' }
        let(:first_param)      { 2 }
        let(:expected_results) { [weight_issue3.iid, weight_issue5.iid, weight_issue1.iid, weight_issue4.iid, weight_issue2.iid] }
      end
    end
```
