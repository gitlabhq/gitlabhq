# GitLab Prometheus metrics

>**Note:**
Available since [Omnibus GitLab 9.3](https://gitlab.com/gitlab-org/gitlab-foss/issues/29118). For
installations from source you'll have to configure it yourself.

To enable the GitLab Prometheus metrics:

1. Log into GitLab as an administrator, and go to the Admin area.
1. Navigate to GitLab's **Settings > Metrics and profiling**.
1. Find the **Metrics - Prometheus** section, and click **Enable Prometheus Metrics**.
1. [Restart GitLab](../../restart_gitlab.md#omnibus-gitlab-restart) for the changes to take effect.

## Collecting the metrics

GitLab monitors its own internal service metrics, and makes them available at the
`/-/metrics` endpoint. Unlike other [Prometheus](https://prometheus.io) exporters, in order to access
it, the client IP needs to be [included in a whitelist](../ip_whitelist.md).

For Omnibus and Chart installations, these metrics are automatically enabled and collected as of [GitLab 9.4](https://gitlab.com/gitlab-org/omnibus-gitlab/merge_requests/1702). For source installations or earlier versions, these metrics will need to be enabled manually and collected by a Prometheus server.

## Metrics available

The following metrics are available:

| Metric                                                         | Type      |                  Since | Description                                                                                         | Labels                                              |
|:---------------------------------------------------------------|:----------|-----------------------:|:----------------------------------------------------------------------------------------------------|:----------------------------------------------------|
| `gitlab_banzai_cached_render_real_duration_seconds`            | Histogram |                    9.4 | Duration of rendering Markdown into HTML when cached output exists                                  | controller, action                                  |
| `gitlab_banzai_cacheless_render_real_duration_seconds`         | Histogram |                    9.4 | Duration of rendering Markdown into HTML when cached outupt does not exist                          | controller, action                                  |
| `gitlab_cache_misses_total`                                    | Counter   |                   10.2 | Cache read miss                                                                                     | controller, action                                  |
| `gitlab_cache_operation_duration_seconds`                      | Histogram |                   10.2 | Cache access time                                                                                   |                                                     |
| `gitlab_cache_operations_total`                                | Counter   |                   12.2 | Cache operations by controller/action                                                               | controller, action, operation                       |
| `gitlab_database_transaction_seconds`                          | Histogram |                   12.1 | Time spent in database transactions, in seconds                                                     |                                                     |
| `gitlab_method_call_duration_seconds`                          | Histogram |                   10.2 | Method calls real duration                                                                          | controller, action, module, method                  |
| `gitlab_rails_queue_duration_seconds`                          | Histogram |                    9.4 | Measures latency between GitLab Workhorse forwarding a request to Rails                             |                                                     |
| `gitlab_sql_duration_seconds`                                  | Histogram |                   10.2 | SQL execution time, excluding SCHEMA operations and BEGIN / COMMIT                                  |                                                     |
| `gitlab_transaction_allocated_memory_bytes`                    | Histogram |                   10.2 | Allocated memory for all transactions (gitlab_transaction_* metrics)                                |                                                     |
| `gitlab_transaction_cache_<key>_count_total`                   | Counter   |                   10.2 | Counter for total Rails cache calls (per key)                                                       |                                                     |
| `gitlab_transaction_cache_<key>_duration_total`                | Counter   |                   10.2 | Counter for total time (seconds) spent in Rails cache calls (per key)                               |                                                     |
| `gitlab_transaction_cache_count_total`                         | Counter   |                   10.2 | Counter for total Rails cache calls (aggregate)                                                     |                                                     |
| `gitlab_transaction_cache_duration_total`                      | Counter   |                   10.2 | Counter for total time (seconds) spent in Rails cache calls (aggregate)                             |                                                     |
| `gitlab_transaction_cache_read_hit_count_total`                | Counter   |                   10.2 | Counter for cache hits for Rails cache calls                                                        | controller, action                                  |
| `gitlab_transaction_cache_read_miss_count_total`               | Counter   |                   10.2 | Counter for cache misses for Rails cache calls                                                      | controller, action                                  |
| `gitlab_transaction_duration_seconds`                          | Histogram |                   10.2 | Duration for all transactions (gitlab_transaction_* metrics)                                        | controller, action                                  |
| `gitlab_transaction_event_build_found_total`                   | Counter   |                    9.4 | Counter for build found for API /jobs/request                                                       |                                                     |
| `gitlab_transaction_event_build_invalid_total`                 | Counter   |                    9.4 | Counter for build invalid due to concurrency conflict for API /jobs/request                         |                                                     |
| `gitlab_transaction_event_build_not_found_cached_total`        | Counter   |                    9.4 | Counter for cached response of build not found for API /jobs/request                                |                                                     |
| `gitlab_transaction_event_build_not_found_total`               | Counter   |                    9.4 | Counter for build not found for API /jobs/request                                                   |                                                     |
| `gitlab_transaction_event_change_default_branch_total`         | Counter   |                    9.4 | Counter when default branch is changed for any repository                                           |                                                     |
| `gitlab_transaction_event_create_repository_total`             | Counter   |                    9.4 | Counter when any repository is created                                                              |                                                     |
| `gitlab_transaction_event_etag_caching_cache_hit_total`        | Counter   |                    9.4 | Counter for etag cache hit.                                                                         | endpoint                                            |
| `gitlab_transaction_event_etag_caching_header_missing_total`   | Counter   |                    9.4 | Counter for etag cache miss - header missing                                                        | endpoint                                            |
| `gitlab_transaction_event_etag_caching_key_not_found_total`    | Counter   |                    9.4 | Counter for etag cache miss - key not found                                                         | endpoint                                            |
| `gitlab_transaction_event_etag_caching_middleware_used_total`  | Counter   |                    9.4 | Counter for etag middleware accessed                                                                | endpoint                                            |
| `gitlab_transaction_event_etag_caching_resource_changed_total` | Counter   |                    9.4 | Counter for etag cache miss - resource changed                                                      | endpoint                                            |
| `gitlab_transaction_event_fork_repository_total`               | Counter   |                    9.4 | Counter for repository forks (RepositoryForkWorker). Only incremented when source repository exists |                                                     |
| `gitlab_transaction_event_import_repository_total`             | Counter   |                    9.4 | Counter for repository imports (RepositoryImportWorker)                                             |                                                     |
| `gitlab_transaction_event_push_branch_total`                   | Counter   |                    9.4 | Counter for all branch pushes                                                                       |                                                     |
| `gitlab_transaction_event_push_commit_total`                   | Counter   |                    9.4 | Counter for commits                                                                                 | branch                                              |
| `gitlab_transaction_event_push_tag_total`                      | Counter   |                    9.4 | Counter for tag pushes                                                                              |                                                     |
| `gitlab_transaction_event_rails_exception_total`               | Counter   |                    9.4 | Counter for number of rails exceptions                                                              |                                                     |
| `gitlab_transaction_event_receive_email_total`                 | Counter   |                    9.4 | Counter for recieved emails                                                                         | handler                                             |
| `gitlab_transaction_event_remote_mirrors_failed_total`         | Counter   |                   10.8 | Counter for failed remote mirrors                                                                   |                                                     |
| `gitlab_transaction_event_remote_mirrors_finished_total`       | Counter   |                   10.8 | Counter for finished remote mirrors                                                                 |                                                     |
| `gitlab_transaction_event_remote_mirrors_running_total`        | Counter   |                   10.8 | Counter for running remote mirrors                                                                  |                                                     |
| `gitlab_transaction_event_remove_branch_total`                 | Counter   |                    9.4 | Counter when a branch is removed for any repository                                                 |                                                     |
| `gitlab_transaction_event_remove_repository_total`             | Counter   |                    9.4 | Counter when a repository is removed                                                                |                                                     |
| `gitlab_transaction_event_remove_tag_total`                    | Counter   |                    9.4 | Counter when a tag is remove for any repository                                                     |                                                     |
| `gitlab_transaction_event_sidekiq_exception_total`             | Counter   |                    9.4 | Counter of Sidekiq exceptions                                                                       |                                                     |
| `gitlab_transaction_event_stuck_import_jobs_total`             | Counter   |                    9.4 | Count of stuck import jobs                                                                          | projects_without_jid_count, projects_with_jid_count |
| `gitlab_transaction_event_update_build_total`                  | Counter   |                    9.4 | Counter for update build for API /jobs/request/:id                                                  |                                                     |
| `gitlab_transaction_new_redis_connections_total`               | Counter   |                    9.4 | Counter for new Redis connections                                                                   |                                                     |
| `gitlab_transaction_queue_duration_total`                      | Counter   |                    9.4 | Duration jobs were enqueued before processing                                                       |                                                     |
| `gitlab_transaction_rails_queue_duration_total`                | Counter   |                    9.4 | Measures latency between GitLab Workhorse forwarding a request to Rails                             | controller, action                                  |
| `gitlab_transaction_view_duration_total`                       | Counter   |                    9.4 | Duration for views                                                                                  | controller, action, view                            |
| `gitlab_view_rendering_duration_seconds`                       | Histogram |                   10.2 | Duration for views (histogram)                                                                      | controller, action, view                            |
| `http_requests_total`                                          | Counter   |                    9.4 | Rack request count                                                                                  | method                                              |
| `http_request_duration_seconds`                                | Histogram |                    9.4 | HTTP response time from rack middleware                                                             | method, status                                      |
| `pipelines_created_total`                                      | Counter   |                    9.4 | Counter of pipelines created                                                                        |                                                     |
| `rack_uncaught_errors_total`                                   | Counter   |                    9.4 | Rack connections handling uncaught errors count                                                     |                                                     |
| `user_session_logins_total`                                    | Counter   |                    9.4 | Counter of how many users have logged in                                                            |                                                     |
| `upload_file_does_not_exist`                                   | Counter   | 10.7 in EE, 11.5 in CE | Number of times an upload record could not find its file                                            |                                                     |
| `failed_login_captcha_total`                                   | Gauge     |                   11.0 | Counter of failed CAPTCHA attempts during login                                                     |                                                     |
| `successful_login_captcha_total`                               | Gauge     |                   11.0 | Counter of successful CAPTCHA attempts during login                                                 |                                                     |

## Metrics controlled by a feature flag

The following metrics can be controlled by feature flags:

| Metric                                                         | Feature Flag                                                       |
|:---------------------------------------------------------------|:-------------------------------------------------------------------|
| `gitlab_method_call_duration_seconds`                          | `prometheus_metrics_method_instrumentation`                        |
| `gitlab_view_rendering_duration_seconds`                       | `prometheus_metrics_view_instrumentation`                          |

## Sidekiq Metrics available for Geo **(PREMIUM)**

Sidekiq jobs may also gather metrics, and these metrics can be accessed if the Sidekiq exporter is enabled (e.g. via
the `monitoring.sidekiq_exporter` configuration option in `gitlab.yml`.

| Metric                                         | Type    | Since | Description | Labels |
|:---------------------------------------------- |:------- |:----- |:----------- |:------ |
| `geo_db_replication_lag_seconds`               | Gauge   | 10.2  | Database replication lag (seconds) | url |
| `geo_repositories`                             | Gauge   | 10.2  | Total number of repositories available on primary | url |
| `geo_repositories_synced`                      | Gauge   | 10.2  | Number of repositories synced on secondary | url |
| `geo_repositories_failed`                      | Gauge   | 10.2  | Number of repositories failed to sync on secondary | url |
| `geo_lfs_objects`                              | Gauge   | 10.2  | Total number of LFS objects available on primary | url |
| `geo_lfs_objects_synced`                       | Gauge   | 10.2  | Number of LFS objects synced on secondary | url |
| `geo_lfs_objects_failed`                       | Gauge   | 10.2  | Number of LFS objects failed to sync on secondary | url |
| `geo_attachments`                              | Gauge   | 10.2  | Total number of file attachments available on primary | url |
| `geo_attachments_synced`                       | Gauge   | 10.2  | Number of attachments synced on secondary | url |
| `geo_attachments_failed`                       | Gauge   | 10.2  | Number of attachments failed to sync on secondary | url |
| `geo_last_event_id`                            | Gauge   | 10.2  | Database ID of the latest event log entry on the primary | url |
| `geo_last_event_timestamp`                     | Gauge   | 10.2  | UNIX timestamp of the latest event log entry on the primary | url |
| `geo_cursor_last_event_id`                     | Gauge   | 10.2  | Last database ID of the event log processed by the secondary | url |
| `geo_cursor_last_event_timestamp`              | Gauge   | 10.2  | Last UNIX timestamp of the event log processed by the secondary | url |
| `geo_status_failed_total`                      | Counter | 10.2  | Number of times retrieving the status from the Geo Node failed | url |
| `geo_last_successful_status_check_timestamp`   | Gauge   | 10.2  | Last timestamp when the status was successfully updated | url |
| `geo_lfs_objects_synced_missing_on_primary`    | Gauge   | 10.7  | Number of LFS objects marked as synced due to the file missing on the primary | url |
| `geo_job_artifacts_synced_missing_on_primary`  | Gauge   | 10.7  | Number of job artifacts marked as synced due to the file missing on the primary | url |
| `geo_attachments_synced_missing_on_primary`    | Gauge   | 10.7  | Number of attachments marked as synced due to the file missing on the primary | url |
| `geo_repositories_checksummed_count`           | Gauge   | 10.7  | Number of repositories checksummed on primary | url |
| `geo_repositories_checksum_failed_count`       | Gauge   | 10.7  | Number of repositories failed to calculate the checksum on primary | url |
| `geo_wikis_checksummed_count`                  | Gauge   | 10.7  | Number of wikis checksummed on primary | url |
| `geo_wikis_checksum_failed_count`              | Gauge   | 10.7  | Number of wikis failed to calculate the checksum on primary | url |
| `geo_repositories_verified_count`              | Gauge   | 10.7  | Number of repositories verified on secondary | url |
| `geo_repositories_verification_failed_count`   | Gauge   | 10.7  | Number of repositories failed to verify on secondary | url |
| `geo_repositories_checksum_mismatch_count`     | Gauge   | 10.7  | Number of repositories that checksum mismatch on secondary | url |
| `geo_wikis_verified_count`                     | Gauge   | 10.7  | Number of wikis verified on secondary | url |
| `geo_wikis_verification_failed_count`          | Gauge   | 10.7  | Number of wikis failed to verify on secondary | url |
| `geo_wikis_checksum_mismatch_count`            | Gauge   | 10.7  | Number of wikis that checksum mismatch on secondary | url |
| `geo_repositories_checked_count`               | Gauge   | 11.1  | Number of repositories that have been checked via `git fsck` | url |
| `geo_repositories_checked_failed_count`        | Gauge   | 11.1  | Number of repositories that have a failure from `git fsck` | url |
| `geo_repositories_retrying_verification_count` | Gauge   | 11.2  | Number of repositories verification failures that Geo is actively trying to correct on secondary  | url |
| `geo_wikis_retrying_verification_count`        | Gauge   | 11.2  | Number of wikis verification failures that Geo is actively trying to correct on secondary | url |

## Database load balancing metrics **(PREMIUM ONLY)**

The following metrics are available:

| Metric                            | Type      | Since                                                         | Description                            |
|:--------------------------------- |:--------- |:------------------------------------------------------------- |:-------------------------------------- |
| `db_load_balancing_hosts`         | Gauge     | [12.3](https://gitlab.com/gitlab-org/gitlab/issues/13630)     | Current number of load balancing hosts |

## Ruby metrics

Some basic Ruby runtime metrics are available:

| Metric                               | Type      | Since | Description |
|:------------------------------------ |:--------- |:----- |:----------- |
| `ruby_gc_duration_seconds`           | Counter   | 11.1  | Time spent by Ruby in GC |
| `ruby_gc_stat_...`                   | Gauge     | 11.1  | Various metrics from [GC.stat] |
| `ruby_file_descriptors`              | Gauge     | 11.1  | File descriptors per process |
| `ruby_memory_bytes`                  | Gauge     | 11.1  | Memory usage by process |
| `ruby_sampler_duration_seconds`      | Counter   | 11.1  | Time spent collecting stats |
| `ruby_process_cpu_seconds_total`     | Gauge     | 12.0  | Total amount of CPU time per process |
| `ruby_process_max_fds`               | Gauge     | 12.0  | Maximum number of open file descriptors per process |
| `ruby_process_resident_memory_bytes` | Gauge     | 12.0  | Memory usage by process, measured in bytes |
| `ruby_process_start_time_seconds`    | Gauge     | 12.0  | UNIX timestamp of process start time |

[GC.stat]: https://ruby-doc.org/core-2.6.3/GC.html#method-c-stat

## Unicorn Metrics

Unicorn specific metrics, when Unicorn is used.

| Metric                       | Type  | Since | Description                                        |
|:-----------------------------|:------|:------|:---------------------------------------------------|
| `unicorn_active_connections` | Gauge | 11.0  | The number of active Unicorn connections (workers) |
| `unicorn_queued_connections` | Gauge | 11.0  | The number of queued Unicorn connections           |
| `unicorn_workers`            | Gauge | 12.0  | The number of Unicorn workers                      |

## Puma Metrics **(EXPERIMENTAL)**

When Puma is used instead of Unicorn, the following metrics are available:

| Metric                                         | Type    | Since | Description |
|:---------------------------------------------- |:------- |:----- |:----------- |
| `puma_workers`                                 | Gauge   | 12.0  | Total number of workers |
| `puma_running_workers`                         | Gauge   | 12.0  | Number of booted workers |
| `puma_stale_workers`                           | Gauge   | 12.0  | Number of old workers |
| `puma_running`                                 | Gauge   | 12.0  | Number of running threads |
| `puma_queued_connections`                      | Gauge   | 12.0  | Number of connections in that worker's "todo" set waiting for a worker thread |
| `puma_active_connections`                      | Gauge   | 12.0  | Number of threads processing a request |
| `puma_pool_capacity`                           | Gauge   | 12.0  | Number of requests the worker is capable of taking right now |
| `puma_max_threads`                             | Gauge   | 12.0  | Maximum number of worker threads |
| `puma_idle_threads`                            | Gauge   | 12.0  | Number of spawned threads which are not processing a request |
| `puma_killer_terminations_total`               | Gauge   | 12.0  | Number of workers terminated by PumaWorkerKiller |

## Metrics shared directory

GitLab's Prometheus client requires a directory to store metrics data shared between multi-process services.
Those files are shared among all instances running under Unicorn server.
The directory needs to be accessible to all running Unicorn's processes otherwise
metrics will not function correctly.

For best performance its advisable that this directory will be located in `tmpfs`.

Its location is configured using environment variable `prometheus_multiproc_dir`.

If GitLab is installed using Omnibus and `tmpfs` is available then metrics
directory will be automatically configured.

[← Back to the main Prometheus page](index.md)
