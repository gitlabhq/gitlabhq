# Generate Sample Prometheus Data

This command will run Prometheus queries for each of the metrics of a specific environment
for a series of time intervals: 30 minutes, 3 hours, 8 hours, 24 hours, 72 hours, and 7 days
to now. The results of each of query are stored under a `sample_metrics` directory as a yaml
file named by the metric's `identifier`. When the environmental variable `USE_SAMPLE_METRICS`
is set, the Prometheus API query is re-routed to `Projects::Environments::SampleMetricsController`
which loads the appropriate data set if it is present within the `sample_metrics` directory.

- This command requires an id from an Environment with an available Prometheus installation.

**Example:**

```
bundle exec rake gitlab:generate_sample_prometheus_data[21]
```
