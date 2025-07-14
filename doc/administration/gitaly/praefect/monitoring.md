---
stage: Data Access
group: Gitaly
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Monitoring Gitaly Cluster (Praefect)
---

To monitor Gitaly Cluster (Praefect), you can use Prometheus metrics. Two separate metrics endpoints are
available from which metrics can be scraped:

- The default `/metrics` endpoint.
- `/db_metrics`, which contains metrics that require database queries.

## Default Prometheus `/metrics` endpoint

The following metrics are available from the `/metrics` endpoint:

- `gitaly_praefect_read_distribution`, a counter to track [distribution of reads](_index.md#distributed-reads).
  It has two labels:

  - `virtual_storage`.
  - `storage`.

  They reflect configuration defined for this instance of Praefect.

- `gitaly_praefect_replication_latency_bucket`, a histogram measuring the amount of time it takes
  for replication to complete after the replication job starts.
- `gitaly_praefect_replication_delay_bucket`, a histogram measuring how much time passes between
  when the replication job is created and when it starts.
- `gitaly_praefect_connections_total`, the total number of connections to Praefect.
- `gitaly_praefect_method_types`, a count of accessor and mutator RPCs per node.

To monitor [strong consistency](_index.md#strong-consistency), you can use the following Prometheus metrics:

- `gitaly_praefect_transactions_total`, the number of transactions created and voted on.
- `gitaly_praefect_subtransactions_per_transaction_total`, the number of times nodes cast a vote for
  a single transaction. This can happen multiple times if multiple references are getting updated in
  a single transaction.
- `gitaly_praefect_voters_per_transaction_total`: the number of Gitaly nodes taking part in a
  transaction.
- `gitaly_praefect_transactions_delay_seconds`, the server-side delay introduced by waiting for the
  transaction to be committed.
- `gitaly_hook_transaction_voting_delay_seconds`, the client-side delay introduced by waiting for
  the transaction to be committed.

To monitor [repository verification](_index.md#repository-verification), use the following Prometheus metrics:

- `gitaly_praefect_verification_jobs_dequeued_total`, the number of verification jobs picked up by the
  worker.
- `gitaly_praefect_verification_jobs_completed_total`, the number of verification jobs completed by the
  worker. The `result` label indicates the end result of the jobs:
  - `valid` indicates the expected replica existed on the storage.
  - `invalid` indicates the replica expected to exist did not exist on the storage.
  - `error` indicates the job failed and has to be retried.
- `gitaly_praefect_stale_verification_leases_released_total`, the number of stale verification leases
  released.

You can also monitor the [Praefect logs](../../logs/_index.md#praefect-logs).

## Database metrics `/db_metrics` endpoint

The following metrics are available from the `/db_metrics` endpoint:

- `gitaly_praefect_unavailable_repositories`, the number of repositories that have no healthy, up to date replicas.
- `gitaly_praefect_replication_queue_depth`, the number of jobs in the replication queue.
- `gitaly_praefect_verification_queue_depth`, the total number of replicas pending verification.
- `gitaly_praefect_read_only_repositories`, the number of repositories in read-only mode in a virtual storage.
  - This metric was [removed](https://gitlab.com/gitlab-org/gitaly/-/issues/4229) in GitLab 15.4.
