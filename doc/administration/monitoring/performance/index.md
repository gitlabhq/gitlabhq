# GitLab Performance Monitoring

CAUTION: **InfluxDB is deprecated in favor of Prometheus:**
InfluxDB support is scheduled to be removed in GitLab 13.0.
You are advised to use [Prometheus](../prometheus/index.md) instead.

GitLab comes with its own application performance measuring system as of GitLab
8.4, simply called "GitLab Performance Monitoring". GitLab Performance Monitoring is available in both the
Community and Enterprise editions.

Apart from this introduction, you are advised to read through the following
documents in order to understand and properly configure GitLab Performance Monitoring:

- [GitLab Configuration](gitlab_configuration.md)
- [InfluxDB Install/Configuration](influxdb_configuration.md)
- [InfluxDB Schema](influxdb_schema.md)
- [Grafana Install/Configuration](grafana_configuration.md)
- [Performance bar](performance_bar.md)
- [Request profiling](request_profiling.md)

NOTE: **Note:**
Omnibus GitLab 8.16 includes Prometheus as an additional tool to collect
metrics. It will eventually replace InfluxDB when their metrics collection is
on par. Read more in the [Prometheus documentation](../prometheus/index.md).

## Introduction to GitLab Performance Monitoring

GitLab Performance Monitoring makes it possible to measure a wide variety of statistics
including (but not limited to):

- The time it took to complete a transaction (a web request or Sidekiq job).
- The time spent in running SQL queries and rendering HAML views.
- The time spent executing (instrumented) Ruby methods.
- Ruby object allocations, and retained objects in particular.
- System statistics such as the process' memory usage and open file descriptors.
- Ruby garbage collection statistics.

Metrics data is written to [InfluxDB](https://www.influxdata.com/products/influxdb-overview/)
over [UDP][influxdb-udp]. Stored data can be visualized using [Grafana](https://grafana.com) or any other application that
supports reading data from InfluxDB. Alternatively data can be queried using the
InfluxDB CLI.

## Metric Types

Two types of metrics are collected:

1. Transaction specific metrics.
1. Sampled metrics, collected at a certain interval in a separate thread.

### Transaction Metrics

Transaction metrics are metrics that can be associated with a single
transaction. This includes statistics such as the transaction duration, timings
of any executed SQL queries, time spent rendering HAML views, etc. These metrics
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
re-generated for every sampling run instead of being generated once and re-used
for the duration of the process' lifetime.

[influxdb-udp]: https://docs.influxdata.com/influxdb/v0.9/write_protocols/udp/
