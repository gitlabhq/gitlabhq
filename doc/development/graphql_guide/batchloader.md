---
stage: Enablement
group: Database
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# GraphQL BatchLoader

GitLab uses the [batch-loader](https://github.com/exAspArk/batch-loader) Ruby gem to optimize and avoid N+1 SQL queries.

It is the properties of the GraphQL query tree that create opportunities for batching like this - disconnected nodes might need the same data, but cannot know about themselves.

## When should you use it?

We should try to batch DB requests as much as possible during GraphQL **query** execution. There is no need to batch loading during **mutations** because they are executed serially. If you need to make a database query, and it is possible to combine two similar (but not identical) queries, then consider using the batch-loader.

When implementing a new endpoint we should aim to minimise the number of SQL queries. For stability and scalability we must also ensure that our queries do not suffer from N+1 performance issues.

## Implementation

Batch loading is useful when a series of queries for inputs `Qα, Qβ, ... Qω` can be combined to a single query for `Q[α, β, ... ω]`. An example of this is lookups by ID, where we can find two users by usernames as cheaply as one, but real-world examples can be more complex.

Batch loading is not suitable when the result sets have different sort-orders, grouping, aggregation or other non-composable features.

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

- `project_id` is the `ID` of the current project being queried
- `loader.call` is used to map the result back to the input key (here a project ID)
- `BatchLoader::GraphQL` returns a lazy object (suspended promise to fetch the data)

Here an [example MR](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/46549) illustrating how to use our `BatchLoading` mechanism.

## How does it work exactly?

Each lazy object knows which data it needs to load and how to batch the query. When we need to use the lazy objects (which we announce by calling `#sync`), they will be loaded along with all other similar objects in the current batch.

Inside the block we execute a batch query for our items (`User`). After that, all we have to do is to call loader by passing an item which was used in `BatchLoader::GraphQL.for` method (`usernames`) and the loaded object itself (`user`):

```ruby
BatchLoader::GraphQL.for(username).batch do |usernames, loader|
  User.by_username(usernames).each do |user|
    loader.call(user.username, user)
  end
end
```

### What does lazy mean?

It is important to avoid syncing batches too early. In the example below we can see how calling sync too early can eliminate opportunities for batching:

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

```ruby
x = find_lazy(1)
y = find_lazy(2)
z = find_lazy(3)

x.sync
y.sync
z.sync

# => will run 1 query
```

## Testing

Any GraphQL field that supports `BatchLoading` should be tested using the `batch_sync` method available in [GraphQLHelpers](https://gitlab.com/gitlab-org/gitlab/-/blob/master/spec/support/helpers/graphql_helpers.rb).

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

We can also use [QueryRecorder](../query_recorder.md) to make sure we are performing only **one SQL query** per call.

```ruby
it 'executes only 1 SQL query' do
  query_count = ActiveRecord::QueryRecorder.new { subject }.count

  expect(query_count).to eq(1)
end
```
