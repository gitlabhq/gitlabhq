---
stage: Systems
group: Cloud Connector
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
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

### Transaction Metrics

Transaction metrics are metrics that can be associated with a single
transaction. This includes statistics such as the transaction duration, timings
of any executed SQL queries, and time spent rendering HAML views. These metrics
are collected for every Rack request and Sidekiq job processed.

### Sampled Metrics

Sampled metrics are metrics that cannot be associated with a single transaction.
Examples include garbage collection statistics and retained Ruby objects. These
metrics are collected at a regular interval. This interval is made up out of two
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
