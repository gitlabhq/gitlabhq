---
stage: Service Management
group: Respond
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
---

# Prometheus metrics development guidelines

## Adding to the library

We strive to support the 2-4 most important metrics for each common system service that supports Prometheus. If you are looking for support for a particular exporter which has not yet been added to the library, additions can be made [to the `common_metrics.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/config/prometheus/common_metrics.yml) file.

### Query identifier

The requirement for adding a new metric is to make each query to have an unique identifier which is used to update the metric later when changed:

```yaml
- group: Response metrics (NGINX Ingress)
  metrics:
    - title: "Throughput"
      y_axis:
        name: "Requests / Sec"
        format: "number"
        precision: 2
      queries:
        - id: response_metrics_nginx_ingress_throughput_status_code
          query_range: 'sum(rate(nginx_upstream_responses_total{upstream=~"%{kube_namespace}-%{ci_environment_slug}-.*"}[2m])) by (status_code)'
          unit: req / sec
          label: Status Code
```

### Update existing metrics

After you add or change an existing common metric, you must [re-run the import script](../administration/raketasks/maintenance.md#import-common-metrics) that queries and updates all existing metrics.

Or, you can create a database migration:

```ruby
class ImportCommonMetrics < Gitlab::Database::Migration[2.1]
  def up
    ::Gitlab::DatabaseImporters::CommonMetrics::Importer.new.execute
  end

  def down
    # no-op
  end
end
```

If a query metric (which is identified by `id:`) is removed, it isn't removed from database by default.
You might want to add additional database migration that makes a decision what to do with removed one.
For example: you might be interested in migrating all dependent data to a different metric.

## GitLab Prometheus metrics

GitLab provides [Prometheus metrics](../administration/monitoring/prometheus/gitlab_metrics.md)
to monitor itself.

### Adding a new metric

This section describes how to add new metrics for self-monitoring
([example](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/15440)).

1. Select the [type of metric](https://gitlab.com/gitlab-org/prometheus-client-mmap#metrics):

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
