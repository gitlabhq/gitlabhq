# GitLab Prometheus metrics

>**Note:**
Available since [Omnibus GitLab 9.3][29118]. For
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

The following metrics are available:

| Metric                            | Type      | Since | Description |
|:--------------------------------- |:--------- |:----- |:----------- |
| db_ping_timeout                   | Gauge     | 9.4   | Whether or not the last database ping timed out |
| db_ping_success                   | Gauge     | 9.4   | Whether or not the last database ping succeeded |
| db_ping_latency_seconds           | Gauge     | 9.4   | Round trip time of the database ping |
| filesystem_access_latency_seconds | Gauge     | 9.4   | Latency in accessing a specific filesystem |
| filesystem_accessible             | Gauge     | 9.4   | Whether or not a specific filesystem is accessible |
| filesystem_write_latency_seconds  | Gauge     | 9.4   | Write latency of a specific filesystem |
| filesystem_writable               | Gauge     | 9.4   | Whether or not the filesystem is writable |
| filesystem_read_latency_seconds   | Gauge     | 9.4   | Read latency of a specific filesystem |
| filesystem_readable               | Gauge     | 9.4   | Whether or not the filesystem is readable |
| http_requests_total               | Counter   | 9.4   | Rack request count |
| http_request_duration_seconds     | Histogram | 9.4   | HTTP response time from rack middleware |
| pipelines_created_total           | Counter   | 9.4   | Counter of pipelines created |
| rack_uncaught_errors_total        | Counter   | 9.4   | Rack connections handling uncaught errors count |
| redis_ping_timeout                | Gauge     | 9.4   | Whether or not the last redis ping timed out |
| redis_ping_success                | Gauge     | 9.4   | Whether or not the last redis ping succeeded |
| redis_ping_latency_seconds        | Gauge     | 9.4   | Round trip time of the redis ping |
| user_session_logins_total         | Counter   | 9.4   | Counter of how many users have logged in |
| filesystem_circuitbreaker_latency_seconds | Gauge | 9.5 | Time spent validating if a storage is accessible |
| filesystem_circuitbreaker         | Gauge     | 9.5   | Whether or not the circuit for a certain shard is broken or not |
| circuitbreaker_storage_check_duration_seconds | Histogram | 10.3 | Time a single storage probe took |
| failed_login_captcha_total        | Gauge | 11.0 | Counter of failed CAPTCHA attempts during login |
| successful_login_captcha_total    | Gauge | 11.0 | Counter of successful CAPTCHA attempts during login |

### Ruby metrics

Some basic Ruby runtime metrics are available:

| Metric                                 | Type      | Since | Description |
|:-------------------------------------- |:--------- |:----- |:----------- |
| ruby_gc_duration_seconds_total         | Counter   | 11.1  | Time spent by Ruby in GC |
| ruby_gc_stat_...                       | Gauge     | 11.1  | Various metrics from [GC.stat] |
| ruby_file_descriptors                  | Gauge     | 11.1  | File descriptors per process |
| ruby_memory_bytes                      | Gauge     | 11.1  | Memory usage by process |
| ruby_sampler_duration_seconds_total    | Counter   | 11.1  | Time spent collecting stats |

[GC.stat]: https://ruby-doc.org/core-2.3.0/GC.html#method-c-stat

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
