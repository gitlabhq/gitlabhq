---
stage: Foundations
group: Import and Integrate
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Principles of Importer Design
---

## Security

- Uploaded files must be validated. Examples:
  - [`BulkImports::FileDownloadService`](https://gitlab.com/gitlab-org/gitlab/-/blob/cd4a880cbb2bc56b3a55f14c1d8370f4385319db/app/services/bulk_imports/file_download_service.rb#L38-46)
  - [`ImportExport::CommandLineUtil`](https://gitlab.com/gitlab-org/gitlab/blob/139690b3aeac69675119ce70f17f70bc1753de48/lib/gitlab/import_export/command_line_util.rb#L134)

## Logging

- Logs should contain the importer type such as `github`, `bitbucket`, `bitbucket_server`. You can find a full list of import sources in [`Gitlab::ImportSources`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/import_sources.rb#L12).
- Logs should include any information likely to aid in debugging:
  - Object identifiers such as `id`, `iid`, and type of object
  - Error or status messages
- Logs should not include sensitive or private information, including but not limited to:
  - Usernames
  - Email addresses
- Where applicable, we should track the error in `Gitlab::Import::ImportFailureService` to aid in displaying errors in the UI.
- Logging should raise an error in development if key identifiers are missing, as demonstrated in [this MR](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/139469).
- A log line should be created before and after each record is imported, containing that record's identifier.

## Performance

- A cache with a default TTL of 24 hours should be used to prevent duplicate database queries and API calls.
- Workers that loop over collections should be equipped with a progress pointer that allows them to pick up where they left off if interrupted.
  - [Example using ID tracking](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/134229)
  - [Example using page counter](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/139775)
- Write-heavy workers should implement [`defer_on_database_health_signal`](../sidekiq/_index.md#deferring-sidekiq-workers) to avoid saturating the database. However, at the time of writing, a [known issue](https://gitlab.com/gitlab-org/gitlab/-/issues/429871#note_1738917399) prevents us from using this.
- We should enforce limits on worker concurrency to avoid saturating resources. You can find an example of this in the Bitbucket [`ParallelScheduling` class](https://gitlab.com/gitlab-org/gitlab/blob/3254590fd2105fcd995f0ccb5e0b3e214c9a59c6/lib/gitlab/bitbucket_import/parallel_scheduling.rb#L76).
- Importers should be tested at scale on a staging environment, especially when implementing new functionality or enabling a feature flag.

## Resilience

- Workers should be idempotent so they can be retried safely in the case of failure.
- Workers should be re-enqueued with a delay that respects concurrent batch limits.
- Individual workers should not run for a long time. Workers that run for a long time can be [interrupted by Sidekiq due to a deploy](../github_importer.md#increasing-sidekiq-interrupts), or be misidentified by `StuckProjectImportJobsWorker` as being part of an import that is stuck and should be failed.
  - If a worker must run for a long time it must [refresh its JID](https://gitlab.com/gitlab-org/gitlab/-/issues/431936) using `Gitlab::Import::RefreshImportJidWorker` to avoid being terminated by `StuckProjectImportJobsWorker`. It may also need to raise its Sidekiq `max_retries_after_interruption`. Refer to the [GitHub importer implementation](../github_importer.md#increasing-sidekiq-interrupts).
- Workers that rely on cached values must implement fall-back mechanisms to fetch data in the event of a cache miss.
  - Re-fetch data if possible and performant.
  - Gracefully handle missing values.
- Long-running workers should be annotated with `worker_resource_boundary :memory` to place them on a shard with a two hour termination grace period. A long termination grace period is not a replacement for writing fast workers. Apdex SLO compliance can be monitored on the [I&I team Grafana dashboard](https://dashboards.gitlab.net/d/stage-groups-detail-import_and_integrate/b57e3a54-0277-50ff-a67e-4b69c1349274?from=now-7d&orgId=1).
- Workers that create data should not fail an entire import if a single record fails to import. They must log the appropriate error and make a decision on whether or not to retry based on the nature of the error.
- Import _Stage_ workers (which include `StageMethods`) and _Advance Stage_ workers (which include `Gitlab::Import::AdvanceStage`) should have `retries: 6` to make them more resilient to system interruptions. With exponential back-off, six retries spans approximately 20 minutes. Any higher retry holds up an import for too long.
- It should be possible to retry a portion of an import, for example re-importing missing issues without overwriting the entire destination project.

## Consistency

- Importers should fire callbacks after saving records. Problematic callbacks can be disabled for imports on an individual basis:
  - Include the [`Importable`](https://gitlab.com/gitlab-org/gitlab/blob/15b878e27e8188e9d22755fd648f75de313f012f/app/models/concerns/importable.rb) module.
  - Configure the callback to skip if `importing?`.
  - Set the `importing` value on the object under import.
- If records must be inserted in bulk, consider manually running callbacks.
