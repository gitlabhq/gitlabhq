# How it works

## Async processing

A cron worker triggers a Sidekiq job for every queue in `ActiveContext.raw_queues` every minute. For each of the jobs, it fetches a set amount of references from the queue, processes them and removes them from the queue. The job will re-enqueue itself every second until there are no more references to process in the queue.

Async processing depends on the following configuration values:
  
  1. `indexing_enabled`: processing exits early if this is false. Recommended to set to:

      ```ruby
      config.indexing_enabled = Gitlab::CurrentSettings.elasticsearch_indexing? &&
        Search::ClusterHealthCheck::Elastic.healthy? &&
        !Elastic::IndexingControl.non_cached_pause_indexing?
      ```

  1. `re_enqueue_indexing_workers`: whether or not to re-enqueue workers until there are no more references to process. Increases indexing throughput when set to `true`. Recommended to set to:

      ```ruby
      config.re_enqueue_indexing_workers = Gitlab::CurrentSettings.elasticsearch_requeue_workers?
      ```
