# How it works

## Migrations

A cron worker runs every 5 minutes to apply outstanding migrations for the currently active connection.

If another connection is made active, the worker will apply that connection's outstanding migrations.

## Async processing

A cron worker triggers a Sidekiq job for every queue in `ActiveContext.raw_queues` every minute. For each of the jobs, it fetches a set amount of references from the queue, processes them and removes them from the queue. The job will re-enqueue itself every second until there are no more references to process in the queue.

A queue class can define `processing_delay`. Items pushed to a delayed queue only become eligible for processing after the delay: the processing path fetches with `due_only: true`, while all other reads (introspection, maintenance tasks) see every item in the queue.

Failed items move through a chain of retry queues with increasing delays: `RetryQueue` (5 minutes), `SecondRetryQueue` (30 minutes), `ThirdRetryQueue` (2 hours), and `FourthRetryQueue` (8 hours). Each stage gives one retry, and each failure moves the item to the next stage. The delays give transient errors, such as AI Gateway timeouts, time to clear between attempts. Items that fail every stage go to the dead queue, which is never processed automatically. Each queue class defines its `failure_queue`, so the attempt count lives in the queue topology and items need no extra state.

Async processing depends on the following configuration values:

  1. `indexing_enabled`: processing exits early if this is false. Recommended to set to:

      ```ruby
      config.indexing_enabled = Gitlab::CurrentSettings.elasticsearch_indexing? &&
        Search::ClusterHealthCheck::Elastic.healthy?
      ```

  1. `re_enqueue_indexing_workers`: whether or not to re-enqueue workers until there are no more references to process. Increases indexing throughput when set to `true`. Recommended to set to:

      ```ruby
      config.re_enqueue_indexing_workers = Gitlab::CurrentSettings.elasticsearch_requeue_workers?
      ```
