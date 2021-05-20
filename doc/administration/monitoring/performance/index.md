---
stage: Monitor
group: Monitor
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# GitLab Performance Monitoring **(FREE SELF)**

GitLab comes with its own application performance measuring system as of GitLab
8.4, called "GitLab Performance Monitoring". GitLab Performance Monitoring is available in both the
Community and Enterprise editions.

Apart from this introduction, you are advised to read through the following
documents to understand and properly configure GitLab Performance Monitoring:

- [GitLab Configuration](gitlab_configuration.md)
- [Prometheus documentation](../prometheus/index.md)
- [Grafana Install/Configuration](grafana_configuration.md)
- [Performance bar](performance_bar.md)
- [Request profiling](request_profiling.md)

## Introduction to GitLab Performance Monitoring

GitLab Performance Monitoring makes it possible to measure a wide variety of statistics
including (but not limited to):

- The time it took to complete a transaction (a web request or Sidekiq job).
- The time spent in running SQL queries and rendering HAML views.
- The time spent executing (instrumented) Ruby methods.
- Ruby object allocations, and retained objects in particular.
- System statistics such as the process' memory usage and open file descriptors.
- Ruby garbage collection statistics.

## Metric Types

Two types of metrics are collected:

1. Transaction specific metrics.
1. Sampled metrics, collected at a certain interval in a separate thread.

### Transaction Metrics

Transaction metrics are metrics that can be associated with a single
transaction. This includes statistics such as the transaction duration, timings
of any executed SQL queries, time spent rendering HAML views, and so on. These metrics
are collected for every Rack request and Sidekiq job processed.

### Sampled Metrics

Sampled metrics are metrics that can't be associated with a single transaction.
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
