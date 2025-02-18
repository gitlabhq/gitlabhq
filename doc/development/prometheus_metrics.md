---
stage: Monitor
group: Platform Insights
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: GitLab Prometheus metrics development guidelines
---

GitLab provides [Prometheus metrics](../administration/monitoring/prometheus/gitlab_metrics.md)
to monitor itself.

## Adding a new metric

This section describes how to add new metrics for self-monitoring
([example](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/15440)).

1. Select the [type of metric](https://gitlab.com/gitlab-org/ruby/gems/prometheus-client-mmap#metrics):

   - `Gitlab::Metrics.counter`
   - `Gitlab::Metrics.gauge`
   - `Gitlab::Metrics.histogram`
   - `Gitlab::Metrics.summary`

1. Select the appropriate name for your metric. Refer to the guidelines
   for [Prometheus metric names](https://prometheus.io/docs/practices/naming/#metric-names).
1. Update the list of [GitLab Prometheus metrics](../administration/monitoring/prometheus/gitlab_metrics.md).
1. Carefully choose what labels you want to add to your metric. Values with high cardinality,
   like `project_path`, or `project_id` are strongly discouraged because they can affect our services
   availability due to the fact that each set of labels is exposed as a new entry in the `/metrics` endpoint.
   For example, a histogram with 10 buckets and a label with 100 values would generate 1000
   entries in the export endpoint.
1. Trigger the relevant page or code that records the new metric.
1. Check that the new metric appears at `/-/metrics`.

For metrics that are not bounded to a specific context (`request`, `process`, `machine`, `namespace`, etc),
generate them from a cron-based Sidekiq job:

- For Geo related metrics, check `Geo::MetricsUpdateService`.
- For other "global" / instance-wide metrics, check: `Metrics::GlobalMetricsUpdateService`.

When exporting data from Sidekiq in an installation with more than one Sidekiq instance,
you are not guaranteed that the same exporter will always be queried.

You can read more and understand the caveats in [issue 406583](https://gitlab.com/gitlab-org/gitlab/-/issues/406583),
where we also discuss a possible solution using a push-gateway.
