---
stage: Shared responsibility based on functional area
group: Shared responsibility based on functional area
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: no
title: GitLab Performance Monitoring
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

Detect performance bottlenecks before they affect your users with GitLab Performance
Monitoring. When slow response times or memory issues occur, pinpoint their exact
cause through detailed metrics on SQL queries, Ruby processing, and system resources.

Administrators who implement performance monitoring gain immediate alerts to
potential problems before they cascade into instance-wide issues. Track transaction
times, query execution performance, and memory usage to maintain optimal GitLab
performance for your organization.

For more information on how to configure GitLab Performance Monitoring, see the:

- [Prometheus documentation](../prometheus/_index.md).
- [Grafana configuration](grafana_configuration.md).
- [Performance bar](performance_bar.md).

Two types of metrics are collected:

1. Transaction specific metrics.
1. Sampled metrics.

## Transaction Metrics

Transaction metrics are metrics that can be associated with a single
transaction. This includes statistics such as the transaction duration, timings
of any executed SQL queries, and time spent rendering HAML views. These metrics
are collected for every Rack request and Sidekiq job processed.

## Sampled Metrics

Sampled metrics are metrics that cannot be associated with a single transaction.
Examples include garbage collection statistics and retained Ruby objects. These
metrics are collected at a regular interval. This interval is made up of two
parts:

1. A user defined interval.
1. A randomly generated offset added on top of the interval, the same offset
   can't be used twice in a row.

The actual interval can be anywhere between a half of the defined interval and a
half above the interval. For example, for a user defined interval of 15 seconds
the actual interval can be anywhere between 7.5 and 22.5. The interval is
re-generated for every sampling run instead of being generated one time and reused
for the duration of the process' lifetime.

User defined intervals can be specified by means of environment variables.
The following environment variables are recognized:

- `RUBY_SAMPLER_INTERVAL_SECONDS`
- `DATABASE_SAMPLER_INTERVAL_SECONDS`
- `ACTION_CABLE_SAMPLER_INTERVAL_SECONDS`
- `PUMA_SAMPLER_INTERVAL_SECONDS`
- `THREADS_SAMPLER_INTERVAL_SECONDS`
- `GLOBAL_SEARCH_SAMPLER_INTERVAL_SECONDS`
- `PG_ASH_SAMPLER_INTERVAL_SECONDS`

## Active session history

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Status: Experiment

{{< /details >}}

{{< history >}}

- Introduced in GitLab 19.5 as an [experiment](../../../policy/development_stages_support.md).

{{< /history >}}

Active session history samples `pg_stat_activity` on the main database, so you can see what the
database was doing at a point in the past.
GitLab vendors [pg_ash](https://github.com/NikolayS/pg_ash) to collect and store the samples.

This feature is an experiment and is not ready for production use.
Test it outside of production first.

`pg_ash` is not installed by default, and sampling is off by default.

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

To install `pg_ash`:

```shell
sudo gitlab-rake gitlab:db:pg_ash:install
```

To check an install:

```shell
sudo gitlab-rake gitlab:db:pg_ash:status
```

To remove `pg_ash` and every sample it holds:

```shell
sudo gitlab-rake gitlab:db:pg_ash:uninstall
```

{{< /tab >}}

{{< tab title="Helm chart (Kubernetes)" >}}

To install `pg_ash`:

```shell
kubectl exec -it <toolbox-pod-name> -- gitlab-rake gitlab:db:pg_ash:install
```

To check an install:

```shell
kubectl exec -it <toolbox-pod-name> -- gitlab-rake gitlab:db:pg_ash:status
```

To remove `pg_ash` and every sample it holds:

```shell
kubectl exec -it <toolbox-pod-name> -- gitlab-rake gitlab:db:pg_ash:uninstall
```

{{< /tab >}}

{{< tab title="Docker" >}}

To install `pg_ash`:

```shell
sudo docker exec -t <container-name> gitlab-rake gitlab:db:pg_ash:install
```

To check an install:

```shell
sudo docker exec -t <container-name> gitlab-rake gitlab:db:pg_ash:status
```

To remove `pg_ash` and every sample it holds:

```shell
sudo docker exec -t <container-name> gitlab-rake gitlab:db:pg_ash:uninstall
```

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

To install `pg_ash`:

```shell
sudo -u git -H bundle exec rake gitlab:db:pg_ash:install RAILS_ENV=production
```

To check an install:

```shell
sudo -u git -H bundle exec rake gitlab:db:pg_ash:status RAILS_ENV=production
```

To remove `pg_ash` and every sample it holds:

```shell
sudo -u git -H bundle exec rake gitlab:db:pg_ash:uninstall RAILS_ENV=production
```

{{< /tab >}}

{{< /tabs >}}

To turn on sampling:

1. Sign in as a user with administrator access.
1. In the upper-right corner, select **Admin**.
1. In the left sidebar, select **Settings** > **Metrics and profiling**.
1. Expand the **Active session history** section.
1. Select the **Turn on session sampling** checkbox.
1. Optional. Change **Sample interval (seconds)**. The default is one second.
1. Select **Save changes**.

A background thread in the Sidekiq process takes the samples.
Only one process samples at a time, so the interval you set is the interval for the whole instance.
Sampling needs the GitLab Prometheus metrics endpoint, which is on by default.
Sampling stops when Sidekiq stops, so a restart or a deployment can lose samples.

A change to either setting applies without a restart, but not at once.
Each Sidekiq process reads the new value in up to 90 seconds.

`PG_ASH_SAMPLER_INTERVAL_SECONDS` sets how often a Sidekiq process checks whether it should take
over as the sampling process.
It does not set the sample interval.

### Rollup and retention

While sampling is on, Sidekiq cron jobs summarize and remove old samples:

| Job | Runs | Effect |
|-----|------|--------|
| `pg_ash_rollup_minute_worker` | Every minute | Summarizes raw samples into one row per minute. |
| `pg_ash_rollup_hour_worker` | Every hour | Summarizes minute rows into one row per hour. |
| `pg_ash_rotate_worker` | Every hour from 00:03 to 05:03 | Removes the oldest day of raw samples once a day. The other runs are retries. |
| `pg_ash_rollup_cleanup_worker` | Every hour from 03:07 to 05:07 | Removes minute and hour rows older than their retention. |

Times are in the [cron jobs time zone](../../settings/sidekiq.md#cron-jobs-time-zone), UTC by default.

With the `pg_ash` defaults, raw samples are kept for one full day plus the current day,
minute rows for 30 days, and hour rows for five years.
The retention values are in the `ash.config` table.
An admin setting for them is proposed in
[issue 608100](https://gitlab.com/gitlab-org/gitlab/-/work_items/608100).

Raw samples are removed only after they are summarized.
If a rotation cannot confirm this, it fails and the `gitlab_pg_ash_consecutive_rotate_failures`
metric increases. The `gitlab:db:pg_ash:status` Rake task shows the same counter.

The jobs stop when you turn off sampling. Data collected until then stays until you uninstall `pg_ash`.
