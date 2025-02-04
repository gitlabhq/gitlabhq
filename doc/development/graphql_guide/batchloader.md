---
stage: Data Access
group: Database Frameworks
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: GraphQL BatchLoader
---

GitLab uses the [batch-loader](https://github.com/exAspArk/batch-loader) Ruby gem to optimize and avoid N+1 SQL queries.

It is the properties of the GraphQL query tree that create opportunities for batching like this - disconnected nodes might need the same data, but cannot know about themselves.

## When should you use it?

We should try to batch DB requests as much as possible during GraphQL **query** execution. There is no need to batch loading during **mutations** because they are executed serially. If you need to make a database query, and it is possible to combine two similar (but not necessarily identical) queries, then consider using the batch-loader.

When implementing a new endpoint we should aim to minimise the number of SQL queries. For stability and scalability we must also ensure that our queries do not suffer from N+1 performance issues.

## Implementation

Batch loading is useful when a series of queries for inputs `Qα, Qβ, ... Qω` can be combined to a single query for `Q[α, β, ... ω]`. An example of this is lookups by ID, where we can find two users by usernames as cheaply as one, but real-world examples can be more complex.

Batch loading is not suitable when the result sets have different sort orders, grouping, aggregation, or other non-composable features.

There are two ways to use the batch-loader in your code. For simple ID lookups, use `::Gitlab::Graphql::Loaders::BatchModelLoader.new(model, id).find`. For more complex cases, you can use the batch API directly.

For example, to load a `User` by `username`, we can add batching as follows:

```ruby
class UserResolver < BaseResolver
  type UserType, null: true
  argument :username, ::GraphQL::Types::String, required: true

  def resolve(**args)
    BatchLoader::GraphQL.for(username).batch do |usernames, loader|
      User.by_username(usernames).each do |user|
        loader.call(user.username, user)
      end
    end
  end
end
```

- `username` is the username we want to query. It can be one name or multiple names.
- `loader.call` is used to map the result back to the input key (here user is mapped to its username)
- `BatchLoader::GraphQL` returns a lazy object (suspended promise to fetch the data)

Here an [example MR](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/46549) illustrating how to use our `BatchLoading` mechanism.

## The `BatchModelLoader`

For ID lookups, the advice is to use the `BatchModelLoader`:

```ruby
def project
  ::Gitlab::Graphql::Loaders::BatchModelLoader.new(::Project, object.project_id).find
end
```

To preload associations, you can pass an array of them:

```ruby
def issue(lookahead:)
  preloads = [:author] if lookahead.selects?(:author)

  ::Gitlab::Graphql::Loaders::BatchModelLoader.new(::Issue, object.issue_id, preloads).find
end
```

## How does it work exactly?

Each lazy object knows which data it needs to load and how to batch the query. When we need to use the lazy objects (which we announce by calling `#sync`), they are loaded along with all other similar objects in the current batch.

Inside the block we execute a batch query for our items (`User`). After that, all we have to do is to call loader by passing an item which was used in `BatchLoader::GraphQL.for` method (`usernames`) and the loaded object itself (`user`):

```ruby
BatchLoader::GraphQL.for(username).batch do |usernames, loader|
  User.by_username(usernames).each do |user|
    loader.call(user.username, user)
  end
end
```

The batch-loader uses the source code location of the block to determine
which requests belong in the same queue, but only one instance of the block
is evaluated for each batch. You do not control which one.

For this reason, it is important that:

- The block must not refer to (close over) any instance state on objects. The best practice
  is to pass all data the block needs through to it in the `for(data)` call.
- The block must be specific to a kind of batched data. Implementing generic
  loaders (such as the `BatchModelLoader`) is possible, but it requires the use
  of an injective `key` argument.
- Batches are not shared unless they refer to the same block - two identical blocks
  with the same behavior, parameters, and keys do not get shared. For this reason,
  never implement batched ID lookups on your own, instead use the `BatchModelLoader` for
  maximum sharing. If you see two fields define the same batch-loading, consider
  extracting that out to a new `Loader`, and enabling them to share.

### What does lazy mean?

It is important to avoid syncing batches (forcing their evaluation) too early. The following example shows how calling sync too early can eliminate opportunities for batching.

This example calls sync on `x` too early:

```ruby
x = find_lazy(1)
y = find_lazy(2)

# calling .sync will flush the current batch and will inhibit maximum laziness
x.sync

z = find_lazy(3)

y.sync
z.sync

# => will run 2 queries
```

However, this example waits until all requests are queued, and eliminates the extra query:

```ruby
x = find_lazy(1)
y = find_lazy(2)
z = find_lazy(3)

x.sync
y.sync
z.sync

# => will run 1 query
```

NOTE:
There is no dependency analysis in the use of batch-loading. There is
a pending queue of requests, and as soon as any one result is needed, all pending
requests are evaluated.

You should never call `batch.sync` or use `Lazy.force` in resolver code.
If you depend on a lazy value, use `Lazy.with_value` instead:

```ruby
def publisher
  ::Gitlab::Graphql::Loaders::BatchModelLoader.new(::Publisher, object.publisher_id).find
end

# Here we need the publisher to generate the catalog URL
def catalog_url
  ::Gitlab::Graphql::Lazy.with_value(publisher) do |p|
    UrlHelpers.book_catalog_url(publisher, object.isbn)
  end
end
```

We commonly use `#sync` in a mutation after finding a record with `GitlabSchema.find_by_gid` or `.object_from_id`, as those methods return the result in a batch loader wrapper. Mutations are executed serially, so batch loading is not necessary and the object can be evaluated immediately.

## Testing

Ideally, do all your testing using request specs, and using `Schema.execute`. If
you do so, you do not need to manage the lifecycle of lazy values yourself, and
you are assured accurate results.

GraphQL fields that return lazy values may need these values forced in tests.
Forcing refers to explicit demands for evaluation, where this would usually
be arranged by the framework.

You can force a lazy value with the `GraphqlHelpers#batch_sync` method available in [GraphQLHelpers](https://gitlab.com/gitlab-org/gitlab/-/blob/master/spec/support/helpers/graphql_helpers.rb), or by using `Gitlab::Graphql::Lazy.force`. For example:

```ruby
it 'returns data as a batch' do
  results = batch_sync(max_queries: 1) do
    [{ id: 1 }, { id: 2 }].map { |args| resolve(args) }
  end

  expect(results).to eq(expected_results)
end

def resolve(args = {}, context = { current_user: current_user })
  resolve(described_class, obj: obj, args: args, ctx: context)
end
```

We can also use [QueryRecorder](../database/query_recorder.md) to make sure we are performing only **one SQL query** per call.

```ruby
it 'executes only 1 SQL query' do
  query_count = ActiveRecord::QueryRecorder.new { subject }

  expect(query_count).not_to exceed_query_limit(1)
end
```
