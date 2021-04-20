---
stage: Monitor
group: Monitor
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Generate sample Prometheus data **(FREE SELF)**

This command runs Prometheus queries for each of the metrics of a specific environment
for a series of time intervals to now:

- 30 minutes
- 3 hours
- 8 hours
- 24 hours
- 72 hours
- 7 days

The results of each of query are stored under a `sample_metrics` directory as a YAML
file named by the metric's `identifier`. When the environmental variable `USE_SAMPLE_METRICS`
is set, the Prometheus API query is re-routed to `Projects::Environments::SampleMetricsController`
which loads the appropriate data set if it is present within the `sample_metrics` directory.

This command requires an ID from an environment with an available Prometheus installation.

## Example

The following example demonstrates how to run the Rake task:

```shell
bundle exec rake gitlab:generate_sample_prometheus_data[21]
```
