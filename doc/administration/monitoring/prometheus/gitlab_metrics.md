# GitLab Prometheus metrics

>**Note:**
Available since [Omnibus GitLab 9.3][29118]. Currently experimental. For
installations from source you'll have to configure it yourself.

To enable the GitLab Prometheus metrics:

1. Log into GitLab as an administrator, and go to the Admin area.
1. Click on the gear, then click on Settings.
1. Find the `Metrics - Prometheus` section, and click `Enable Prometheus Metrics`
1. [Restart GitLab][restart] for the changes to take effect

## Collecting the metrics

GitLab monitors its own internal service metrics, and makes them available at the
`/-/metrics` endpoint. Unlike other [Prometheus] exporters, in order to access
it, the client IP needs to be [included in a whitelist][whitelist].

Currently the embedded Prometheus server is not automatically configured to
collect metrics from this endpoint. We recommend setting up another Prometheus
server, because the embedded server configuration is overwritten once every
[reconfigure of GitLab][reconfigure]. In the future this will not be required.

## Unicorn Metrics available

In this experimental phase, only a few metrics are available:

| Metric                                        | Type      | Since | Description |
|:--------------------------------------------- |:--------- |:----- |:----------- |
| db_ping_timeout                               | Gauge     | 9.4   | Whether or not the last database ping timed out |
| db_ping_success                               | Gauge     | 9.4   | Whether or not the last database ping succeeded |
| db_ping_latency_seconds                       | Gauge     | 9.4   | Round trip time of the database ping |
| filesystem_access_latency_seconds             | Gauge     | 9.4   | Latency in accessing a specific filesystem |
| filesystem_accessible                         | Gauge     | 9.4   | Whether or not a specific filesystem is accessible |
| filesystem_write_latency_seconds              | Gauge     | 9.4   | Write latency of a specific filesystem |
| filesystem_writable                           | Gauge     | 9.4   | Whether or not the filesystem is writable |
| filesystem_read_latency_seconds               | Gauge     | 9.4   | Read latency of a specific filesystem |
| filesystem_readable                           | Gauge     | 9.4   | Whether or not the filesystem is readable |
| http_requests_total                           | Counter   | 9.4   | Rack request count |
| http_request_duration_seconds                 | Histogram | 9.4   | HTTP response time from rack middleware |
| pipelines_created_total                       | Counter   | 9.4   | Counter of pipelines created |
| rack_uncaught_errors_total                    | Counter   | 9.4   | Rack connections handling uncaught errors count |
| redis_ping_timeout                            | Gauge     | 9.4   | Whether or not the last redis ping timed out |
| redis_ping_success                            | Gauge     | 9.4   | Whether or not the last redis ping succeeded |
| redis_ping_latency_seconds                    | Gauge     | 9.4   | Round trip time of the redis ping |
| user_session_logins_total                     | Counter   | 9.4   | Counter of how many users have logged in |
| filesystem_circuitbreaker_latency_seconds     | Gauge | 9.5 | Time spent validating if a storage is accessible |
| filesystem_circuitbreaker                     | Gauge     | 9.5   | Whether or not the circuit for a certain shard is broken or not |
| circuitbreaker_storage_check_duration_seconds | Histogram | 10.3 | Time a single storage probe took |
| upload_file_does_not_exist                    | Counter   | 10.7  | Number of times an upload record could not find its file |

## Sidekiq Metrics available

Sidekiq jobs may also gather metrics, and these metrics can be accessed if the Sidekiq exporter is enabled (e.g. via
the `monitoring.sidekiq_exporter` configuration option in `gitlab.yml`.

| Metric                                      | Type    | Since | Description | Labels |
|:------------------------------------------- |:------- |:----- |:----------- |:------ |
| geo_db_replication_lag_seconds              | Gauge   | 10.2  | Database replication lag (seconds) | url
| geo_repositories                            | Gauge   | 10.2  | Total number of repositories available on primary | url
| geo_repositories_synced                     | Gauge   | 10.2  | Number of repositories synced on secondary | url
| geo_repositories_failed                     | Gauge   | 10.2  | Number of repositories failed to sync on secondary | url
| geo_lfs_objects                             | Gauge   | 10.2  | Total number of LFS objects available on primary | url
| geo_lfs_objects_synced                      | Gauge   | 10.2  | Number of LFS objects synced on secondary | url
| geo_lfs_objects_failed                      | Gauge   | 10.2  | Number of LFS objects failed to sync on secondary | url
| geo_attachments                             | Gauge   | 10.2  | Total number of file attachments available on primary | url
| geo_attachments_synced                      | Gauge   | 10.2  | Number of attachments synced on secondary | url
| geo_attachments_failed                      | Gauge   | 10.2  | Number of attachments failed to sync on secondary | url
| geo_last_event_id                           | Gauge   | 10.2  | Database ID of the latest event log entry on the primary | url
| geo_last_event_timestamp                    | Gauge   | 10.2  | UNIX timestamp of the latest event log entry on the primary | url
| geo_cursor_last_event_id                    | Gauge   | 10.2  | Last database ID of the event log processed by the secondary | url
| geo_cursor_last_event_timestamp             | Gauge   | 10.2  | Last UNIX timestamp of the event log processed by the secondary | url
| geo_status_failed_total                     | Counter | 10.2  | Number of times retrieving the status from the Geo Node failed | url
| geo_last_successful_status_check_timestamp  | Gauge   | 10.2  | Last timestamp when the status was successfully updated | url
| geo_lfs_objects_synced_missing_on_primary   | Gauge   | 10.7  | Number of LFS objects marked as synced due to the file missing on the primary | url
| geo_job_artifacts_synced_missing_on_primary | Gauge   | 10.7  | Number of job artifacts marked as synced due to the file missing on the primary | url
| geo_attachments_synced_missing_on_primary   | Gauge   | 10.7  | Number of attachments marked as synced due to the file missing on the primary | url

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

[29118]: https://gitlab.com/gitlab-org/gitlab-ce/issues/29118
[Prometheus]: https://prometheus.io
[restart]: ../../restart_gitlab.md#omnibus-gitlab-restart
[whitelist]: ../ip_whitelist.md
[reconfigure]: ../../restart_gitlab.md#omnibus-gitlab-reconfigure
