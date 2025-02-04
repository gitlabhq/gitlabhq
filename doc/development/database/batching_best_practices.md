---
stage: Data Access
group: Database Frameworks
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Batching best practices
---

This document gives an overview about the available batching strategies we use at GitLab. We list the pros and cons of each strategy so engineers can pick the ideal approach for their use case.

## Why do we need batching

When dealing with a large volume of records, reading, updating or deleting the records in one database query can be challenging; the operation could easily time out. To avoid this problem, we should process the records in batches. Batching usually happens in background jobs, where runtime constraints are more relaxed than during web requests.

### Use batching in background jobs and not in web requests

In rare cases (older features), batching also happens in web requests. However, for new features this is discouraged due to the short web request timeout (60 seconds by default). As a guideline, using background jobs (Sidekiq workers) should be considered as the first option when implementing a feature that needs to process a large volume of records.

### Performance considerations

Batching performance is closely related to pagination performance since the underlying libraries and database queries are essentially the same. When implementing batching it's important to be familiar with the [pagination performance guidelines](pagination_performance_guidelines.md) and the documentation related to our [batching utilities](iterating_tables_in_batches.md).

## Batching in background jobs

There are two main aspects to consider when implementing batching in background jobs: total runtime and data modification volume.

Background jobs shouldn't run for a long time. A Sidekiq process can crash or it can be forcefully stopped (e.g. on restart or deployment). Additionally, due to our [error budget](../stage_group_observability/_index.md#error-budget) rules, after 5 minutes of runtime, error budget violations will be added to the group where the feature is registered. When implementing batching in background jobs, make sure that you're familiar with our guidelines related to [idempotent jobs](../sidekiq/idempotent_jobs.md)

Updating or deleting a large volume of records can increase database replication lag and it can add extra strain to the primary database. It's advisable to limit the total number of records we process (or batch over) within the background job.

To address the potential issues mentioned above the following measures should be considered:

- Limit the total runtime for the job.
- Limit record modifications.
- Rest period between batches. (a few milliseconds)

When applying limits, it's important to mention that long-running background jobs should implement a "continue later" mechanism where a new job is scheduled after the limit is reached to continue the work where the batching was stopped. This is important when a job is so long that it's very likely that it won't fit into the 5 minutes runtime.

An example implementation of runtime limiting using the `Gitlab::Metrics::RuntimeLimiter` class:

```ruby
def perform(project_id)
  runtime_limiter = Gitlab::Metrics::RuntimeLimiter.new(3.minutes)

  project = Project.find(1)
  project.issues.each_batch(of: :iid) do |scope|
    scope.update_all(updated_at: Time.current)
    break if runtime_limiter.over_time?
  end
end
```

The batching in the code snippet stops when 3 minutes of runtime is reached. The problem now is that we have no way to continue the processing. To do that, we need to schedule a new background job with enough information to continue the processing. In the snippet, we batch issues within a project by the `iid` column. For the next job, we need to provide the project ID and the last processed `iid` values. This information we often call as the cursor.

```ruby
def perform(project_id, iid = nil)
  runtime_limiter = Gitlab::Metrics::RuntimeLimiter.new(3.minutes)

  project = Project.find(project_id)
  # Restore the previous iid if present
  project.issues.where('iid > ?', iid || 0).each_batch(of: :iid) do |scope|
    max_iid = scope.maximum(:iid)
    scope.update_all(updated_at: Time.current)

    if runtime_limiter.over_time?
      MyJob.perform_in(2.minutes, project_id, iid)

      break
    end
  end
end
```

Implementing a "continue later" mechanism can add significant complexity to the implementation. Hence, before committing to this work, analyze the existing data in the production database and try to extrapolate data growth. A few examples:

- Mark all `pending` todos for a given user as `done` does not need a "continue later" mechanism.
  - Reasoning: The number of pending todos will most likely not going to be over a few thousand database rows, even for the busiest users. Updating these rows would finish 99.9% of the time under 1 minute.
- Store CI build records in a CSV files within a given project might require a "continue later" mechanism.
  - Reasoning: for very active projects, CI job count can grow at a very high rate into millions of rows.

When a very large volume of updates happen in the background job, it's advisable (not a strict requirement) to add some sleep to the code and limit the total number of records we update. This reduces the pressure on the primary databases and gives a small window for potential database migrations to acquire heavier locks.

```ruby
def perform(project_id, iid = nil)
  max_updates = 100_000 # Allow maximum N updates
  updates = 0
  status = :completed
  runtime_limiter = Gitlab::Metrics::RuntimeLimiter.new(3.minutes)

  project = Project.find(project_id)
  project.issues.where('iid > ?', iid || 0).each_batch(of: :iid) do |scope|
    max_iid = scope.maximum(:iid)
    updates += scope.update_all(updated_at: Time.current)

    if runtime_limiter.over_time? || updates >= max_updates
      MyJob.perform_in(2.minutes, project_id, iid)
      status = :limit_reached

      break
    end

    # Adding sleep when we expect long running batching that modifies large volume of data
    sleep 0.01
  end
end
```

### Traceability

For traceability purposes, it's a good practice to expose metrics so we can see how the batching performs in Kibana:

```ruby
log_extra_metadata_on_done(:result, {
  status: :limit_reached, # or :completed
  updated_rows: updates
})
```

### Scheduling of the next jobs

Scheduling the next job in the example above is not crash safe (the job can be lost), for very important tasks this approach is not suitable. A safe and common pattern is using a scheduled worker that executes the work based on a cursor. The cursor can be persisted in the DB or in Redis depending on the consistency requirements. This means that the cursor is no longer passed via the job arguments.

The frequency of the scheduled worker can be adjusted depending on the urgency of the task. We have examples when a scheduled worker is enqueued every minute to process urgent items.

#### Redis based cursor

Example: process all issues in a project.

```ruby
def perform
  project_id, iid = load_cursor # Load cursor from Redis

  return unless project_id # Nothing was enqueued

  project = Project.find(project_id)
  project.issues.where('iid > ?', iid || 0).each_batch(of: :iid) do |scope|
    # Do something with issues.
    # Break here, set interrupted flag if time limit is up.
    # Set iid to the last processed value.
  end

  # Continue the work later
  push_cursor(project_id, iid) if interrupted?
end

private

def load_cursor
  # Take 1 element, not crash safe.
  raw_cursor = Gitlab::Redis::SharedState.with do |redis|
    redis.lpop('my_cursor')
  end

  return unless raw_cursor

  cursor = Gitlab::Json.parse(raw_cursor)
  [cursor['project_id'], cursor['iid']]
end

def push_cursor(project_id, iid)
  # Work is not finished, put the cursor at the beginning of the list so the next job can pick it up.
  Gitlab::Redis::SharedState.with do |redis|
    redis.lpush('my_cursor', Gitlab::Json.dump({ project_id: project_id, iid: iid }))
  end
end
```

In the application code, you can put an item in the queue after the database transaction commits (see [transaction guidelines](transaction_guidelines.md) for more details):

```ruby
def execute
  ApplicationRecord.transaction do
    user.save!
    Event.create!(user: user, issue: issue)
  end

  # Application could crash here

  MyRedieQueue.add(user: user, issue: issue)
end
```

This approach is not crash-safe, the item would not be enqueued if the application crashes right after the transaction commits.

Pros:

- Easier to implement, no extra database table is needed for tracking the jobs.
- Good for low throughput, internally invoked jobs. (example: full-table periodical consistency checks, background aggregations)

Cons:

- Scheduling the work (putting the cursor in the queue) is not crash safe.
- Potential serialization issues when the cursor is read (multi-version compatibility).
- Extra care needs to be taken about database transactions.

#### PostgreSQL based cursor

An alternative approach would be storing the queue in the PostgreSQL database. In this case, we can implement the [transactional outbox pattern](https://microservices.io/patterns/data/transactional-outbox) which ensures consistency in case of application (web or worker) crashes.

Pros:

- Scheduling the work can be made fully consistent with other record changes (example: schedule the work within the issue create transaction).
- Tolerates large number of items in the queue.

Cons:

- Depending on the volume, the implementation can be quite complex:
  - Partitioned database table: this should be considered for high-throughput workers.
  - Consider the [sliding-window partitioning strategy](loose_foreign_keys.md#database-partitioning).
  - Complex, cross-partition queries.

Example: set up reliable way of sending emails

```ruby
# In a service
def execute
  ApplicationRecord.transaction do
    user.save!
    Event.create!(user: user, issue: issue)
    IssueEmailWorkerQueue.insert!(user: user, issue: issue)
  end
end
```

The `IssueEmailWorkerQueue` record stores all necessary information for executing a job. In the scheduled background job we can process the table in a specific order.

```ruby
def perform
  runtime_limiter = Gitlab::Metrics::RuntimeLimiter.new(3.minutes)
  items = EmailWorkerQueue.order(:id).take(25)

  items.each do |item|
    # Do something with the item
  end
end
```

NOTE:
To avoid parallel processing of records, you might need to wrap the execution with a distributed Redis lock.

Example Redis lock usage:

```ruby
class MyJob
  include ApplicationWorker
  include Gitlab::ExclusiveLeaseHelpers

  MAX_TTL = 2.5.minutes.to_i # It should be similar to the runtime limit.

  def perform
    in_lock('my_lock_key', ttl: MAX_TTL, retries: 0) do
      # Do the work here.
    end
  end
end
```

### Considerations for Sidekiq jobs

Sidekiq jobs can consume substantial database resources. If your job only batches over data but does not modify anything in the database, consider setting attributes favoring database replicas. See the documentation for the [Sidekiq worker attributes](../sidekiq/worker_attributes.md#job-data-consistency-strategies).

## Batching strategies

NOTE:
To keep the examples easy to follow, we omit the code for limiting the runtime.

NOTE:
Some examples include an optional variable assignment to the `cursor` variable. This is optional step which can be used when implementing the "continue later" mechanism.

### Loop-based batching

The strategy leverages the fact that after updating or deleting records in the database, the exact same query will return different records. This strategy can only be used when we want to delete or update certain records.

Example:

```ruby
loop do
  # Requires an index on project_id
  delete_count = project.issues.limit(1000).delete_all
  break if delete_count == 0 # Exit the loop when there are not records to be deleted
end
```

Pros:

- Easy to implement, maintaining a cursor is not required.
- A single-column database index is sufficient to implement the batching which is often available (foreign keys).
- If order is not important, complex filter conditions can be also used as long as they're covered with an index.

Cons:

- Thorough testing and manual verification of the underlying `DELETE` or `UPDATE` query is a must. There are some issues with [CTEs](../sql.md#when-to-use-common-table-expressions) when updating or deleting records.
- If the `break` logic has a bug we might end up in an infinite loop.

It's possible to make the loop-based approach process records in a specific order:

```ruby
loop do
  # Requires a composite index on (project_id, created_at)
  delete_count = project.issues.limit(1000).order(created_at: :desc).delete_all
  break if delete_count == 0
end
```

With the index mentioned in the previous example, we can also use `timestamp` conditions:

```ruby
loop do
  # Requires a composite index on (project_id, created_at)
  delete_count = project
    .issues
    .where('created_at < ?', 1.month.ago)
    .limit(1000)
    .order(created_at: :desc)
    .delete_all

  break if delete_count == 0
end
```

## Single-column batching

We can use a single, unique column (primary key or column which has a unique index) for batching with the `EachBatch` module. This is one of the most commonly used batching strategy in GitLab.

```ruby
# Requires a composite index on (project_id, id).
# EachBatch uses the primary key by default for the batching.
cursor = nil
project.issues.where('id > ?', cursor || 0).each_batch do |batch|
  issues = batch.to_a
  cursor = issues.last.id # For the next job

  # do something with the issues records
end
```

Pros:

- The most popular way of batching within the GitLab application.
- Easy to implement, covers a wide range of use cases.

Cons:

- The `ORDER BY` column (ID) must be unique in the context of the query.
- It does not work efficiently when `timestamp` column condition or other complex conditions (`IN`, `NOT EXISTS`) are present.

### Batching over distinct values

`EachBatch` requires a unique database column (usually the ID column) however, there are rare cases when the feature needs to batch over a non-unique column. Example: bump all project `timestamp` values which have at least one issue.

One approach is to batch over the "parent" table, in this case using the `Project` model.

```ruby
cursor = nil
# Uses the primary key index
Project.where('id > ?', cursor || 0).each_batch do |batch|
  cursor = batch.maximum(:id) # For the next job

  project_ids = batch
    .where('EXISTS (SELECT 1 FROM issues WHERE projects.id=issues.project_id)')
    .pluck(:id)

  Project.where(id: project_ids).update_all(update_all: Time.current)
end
```

Pros:

- When the column is a foreign key, batching the parent table's primary key should be already covered with an index.

Cons:

- Can be wasteful when the extra condition within the block would match only a small number of rows.

The batching query runs a full table scan over the `projects` table which might be wasteful, alternatively, we can use the `distinct_each_batch` helper method:

```ruby
# requires an index on (project_id)
Issue.distinct_each_batch(column: :project_id) do |scope|
  project_ids = scope.pluck(:project_id)
  cursor = project_ids.last # For the next job

  Project.where(id: project_ids).update_all(update_all: Time.current)
end
```

Pros:

- When the column is a foreign key column then index is already available.
- It can significantly reduce the amount of data the batching logic needs to scan.

Cons:

- Limited usage, not widely used.

## Keyset-based batching

Keyset-based batching allows you to iterate over records in a specific order where multi-column sorting is also possible. The most common use cases are when we need to process data ordered via a `timestamp` column.

Example: delete issue records older than one year.

```ruby
def perform
  cursor = load_cursor || {}
  # Requires a composite index on (created_at, id) columns
  scope = Issue.where('created_at > ?', 1.year.ago).order(:created_at, :id)

  iterator = Gitlab::Pagination::Keyset::Iterator.new(scope: scope, cursor: cursor)

  iterator.each_batch(of: 100) do |records|
    loaded_records = records.to_a

    loaded_records.each { |record| record.destroy } # Calling destroy so callbacks are invoked
  end

  cursor = iterator.send(:cursor) # Store the cursor after this step, for the next job
end
```

With keyset-based batching, you could adjust the `ORDER BY` clause to match the column configuration of an existing index. Consider the following index:

```sql
CREATE INDEX issues_search_index ON issues (project_id, state, created_at, id)
```

This index cannot be used by the snippet above because the `ORDER BY` column list doesn't match exactly the column list in the index definition. However, if we alter the `ORDER BY` clause then the index would be picked up by the query planner:

```ruby
# Note: this is a different sort order but at least we can use an existing index
scope = Issue.where('created_at > ?', 1.year.ago).order(:project_id, :state, :created_at, :id)
```

Pros:

- Multi-column sort orders and more complex filtering are possible.
- You might be able to reuse existing indexes without introducing new ones.

Cons:

- Cursor size could be larger (each `ORDER BY` column will be stored in the cursor).

## Offset batching

This batching technique uses [offset pagination](pagination_guidelines.md#offset-pagination) when loading new records. Offset pagination should be used only as a last resort when the given query cannot be paginated via `EachBatch` or via keyset-pagination. One reason for choosing this technique is when there is no suitable index available for the SQL query to use a different batching technique. Example: in a background job we load too many records without limit and it started to time out. The order of the records are important.

```ruby
def perform(project_id)
  # We have a composite index on (project_id, created_at) columns
  issues = Issue
    .where(project_id: project_id)
    .order(:created_at)
    .to_a

  # do something with the issues
end
```

As the number of issues within the project grows, the query gets slower and eventually times out. Using a different batching technique such as keyset-pagination is not possible because the `ORDER BY` clause is depending on a `timestamp` column which is not unique (see the [tie-breaker](pagination_performance_guidelines.md#tie-breaker-column) section). Ideally, we should order on the `created_at, id` columns, however we don't have that index available. In a time-sensitive scenario (such as an incident) it might not be feasible to introduce a new index right away so as a last resort we can attempt offset pagination.

```ruby
def perform(project_id)
  page = 1

  loop do
    issues = Issue.where(project_id: project_id).order(:created_at).page(page).to_a
    page +=1
    break if issues.empty?

    # do something with the issues
  end
end
```

The snippet above can be a short term fix until a proper solution is in place. It's important to note that offset pagination gets slower as the page number increases which means that there might be a chance where the offset paginated query times out the same way as the original query. The chances are reduced to some extent by the database buffer cache which keeps the previously loaded records in memory; Thus, the consecutive (short-term) lookup of the same rows will not have very high impact on the performance.

Pros:

- Easy to implement.

Cons:

- Performance degrades linearly as the page number is increased.
- This is only a stop-gap measure which shouldn't be used for new features.
- You can store the page number as the cursor but restoring the processing from the previous point can be unreliable.

## Batching over the Group hierarchy

We have several features where we need to query data in the top-level namespace and its subgroups. There are outlier group hierarchies which contain several thousand subgroups or projects. Querying such hierarchies can easily lead to database statement timeouts when additional subqueries or joins are added.

Example: iterate over issues in a group

```ruby
group = Group.find(9970)

Issue.where(project_id: group.all_project_ids).each_batch do |scope|
  # Do something with issues
end
```

The example above will load all subgroups, all projects and all issues in the group hierarchy which will very likely lead to database statement timeout. The query above can be slightly improved with database indexes as a short-term solution.

### Using the in-operator optimization

When you need to process records in a specific order in a group, you can use the [in-operator optimization](efficient_in_operator_queries.md) which can provide better performance than using a standard `each_batch` based batching strategy.

You can see an example for batching over records in the group hierarchy [here](efficient_in_operator_queries.md#batch-iteration).

Pros:

- This is the only way to batch over records efficiently within the group hierarchy in a specific order.

Cons:

- Requires more complex setup.
- Batching over very large hierarchies (high number of projects or subgroups) will require lower batch size.

### Always batch from the top-level group

This technique can be used when we always have to batch from the top-level group (group without parent group). In this case we can leverage the following index in the `namespaces` table:

```sql
"index_on_namespaces_namespaces_by_top_level_namespace" btree ((traversal_ids[1]), type, id) -- traversal_ids[1] is the top-level group id
```

Example batching query:

```ruby
Namespace.where('traversal_ids[1] = ?', 9970).where(type: 'Project').each_batch do |project_namespaces|
  project_ids = Project.where(project_namespace_id: project_namespaces.select(:id)).pluck(:id)
  cursor = project_namespaces.last.id # For the next job

  project_ids.each do |project_id|
    Issue.where(project_id: project_id).each_batch(column: :iid) do |issues|
      # do something with the issues
    end
  end
end
```

Pros:

- Loading the whole group hierarchy can be avoided.
- Processing evenly distributed batches using a nested `EachBatch`.

Cons:

- More database queries due to the double batching.

### Batch from any node from the group hierarchy

Using the `NamespaceEachBatch` class allows us to batch a specific branch of the group hierarchy (tree).

```ruby
# current_id: id of the namespace record where we iterate from
# depth: depth of the tree where the iteration was stopped previously. Initially, it should be the same as the current_id
cursor = { current_id: 9970, depth: [9970] } # This can be any namespace id
iterator = Gitlab::Database::NamespaceEachBatch.new(namespace_class: Namespace, cursor: cursor)

# Requires a composite index on (parent_id, id) columns
iterator.each_batch(of: 100) do |ids, new_cursor|
  namespace_ids = Namespaces::ProjectNamespace.where(id: ids)
  cursor = new_cursor # For the next job, contains the new current_id and depth values

  project_ids = Project.where(project_namespace_id: namespace_ids)
  project_ids.each do |project_id|
    Issue.where(project_id: project_id).each_batch(column: :iid) do |issues|
      # do something with the issues
    end
  end
end
```

Pros:

- It can process the group hierarchy from any node.

Cons:

- Rarely used, useful in only very rare use cases.

### Batching over complex queries

We consider complex queries where the query contains multiple filters and joins. Most of the time these queries cannot be batched easily. A few examples:

- Use [`JOIN`](iterating_tables_in_batches.md#using-join-and-exists) to filter out rows.
- Use [subqueries](iterating_tables_in_batches.md#using-subqueries).
- Use [multiple `IN` filters](efficient_in_operator_queries.md#multiple-in-queries) or complex `AND` or `OR` conditions.
