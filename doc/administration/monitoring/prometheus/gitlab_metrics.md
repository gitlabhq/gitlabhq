# GitLab Prometheus metrics

>**Note:**
Available since [Omnibus GitLab 9.3][29118]. Currently experimental. For installations from source
you'll have to configure it yourself.

GitLab monitors its own internal service metrics, and makes them available at the `/-/metrics` endpoint. Unlike other [Prometheus] exporters, this endpoint requires authentication as it is available on the same URL and port as user traffic.

To enable the GitLab Prometheus metrics:

1. Log into GitLab as an administrator, and go to the Admin area.
1. Click on the gear, then click on Settings.
1. Find the `Metrics - Prometheus` section, and click `Enable Prometheus Metrics`
1. [Restart GitLab][restart] for the changes to take effect

## Collecting the metrics

Since the metrics endpoint is available on the same host and port as other traffic, it requires authentication. The token and URL to access is displayed on the [Health Check][health-check] page.

Currently the embedded Prometheus server is not automatically configured to collect metrics from this endpoint. We recommend setting up another Prometheus server, because the embedded server configuration is overwritten one every reconfigure of GitLab. In the future this will not be required.

## Metrics available

In this experimental phase, only a few metrics are available:

| Metric | Type | Description |
| ------ | ---- | ----------- |
| db_ping_timeout | Gauge | Whether or not the last database ping timed out |
| db_ping_success | Gauge | Whether or not the last database ping succeeded |
| db_ping_latency_seconds | Gauge | Round trip time of the database ping |
| redis_ping_timeout | Gauge | Whether or not the last redis ping timed out |
| redis_ping_success | Gauge | Whether or not the last redis ping succeeded |
| redis_ping_latency_seconds | Gauge | Round trip time of the redis ping |
| filesystem_access_latency_seconds | gauge | Latency in accessing a specific filesystem |
| filesystem_accessible | gauge | Whether or not a specific filesystem is accessible |
| filesystem_write_latency_seconds | gauge | Write latency of a specific filesystem |
| filesystem_writable | gauge | Whether or not the filesystem is writable |
| filesystem_read_latency_seconds | gauge | Read latency of a specific filesystem |
| filesystem_readable | gauge | Whether or not the filesystem is readable |
| user_sessions_logins | Counter | Counter of how many users have logged in | 

[← Back to the main Prometheus page](index.md)

[29118]: https://gitlab.com/gitlab-org/gitlab-ce/issues/29118
[Prometheus]: https://prometheus.io
[restart]: ../../restart_gitlab.md#omnibus-gitlab-restart
[health-check]: ../../../user/admin_area/monitoring/health_check.md
