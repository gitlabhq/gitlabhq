# Prometheus Metrics library

> [Introduced](https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/8935) in GitLab 9.0

GitLab offers automatic detection of select [Prometheus exporters](https://prometheus.io/docs/instrumenting/exporters/). Currently supported exporters are:
* [Kubernetes](kubernetes.md)
* [NGINX](nginx.md)
* [NGINX Ingress Controller](nginx_ingress.md)
* [HAProxy](haproxy.md)
* [Amazon Cloud Watch](cloudwatch.md)

We have tried to surface the most important metrics for each exporter, and will be continuing to add support for additional exporters in future releases. If you would like to add support for other official exporters, [contributions](#adding-to-the-library) are welcome.

## Identifying Environments

GitLab retrieves performance data from the configured Prometheus server, and attempts to identifying the presence of known metrics. Once identified, GitLab then needs to be able to map the data to a particular environment.

In order to isolate and only display relevant metrics for a given environment, GitLab needs a method to detect which labels are associated. To do that,
GitLab uses the defined queries and fills in the environment specific variables. Typically this involves looking for the [$CI_ENVIRONMENT_SLUG](../../../../ci/variables/README.md#predefined-variables-environment-variables), but may also include other information such as the project's Kubernetes namespace. Each search query is defined in the [exporter specific documentation](#prometheus-metrics-library).

## Adding to the library

We strive to support the 2-4 most important metrics for each common system service that supports Prometheus. If you are looking for support for a particular exporter which has not yet been added to the library, additions can be made [to the `common_metrics.yml`](https://gitlab.com/gitlab-org/gitlab-ce/blob/master/config/prometheus/common_metrics.yml) file.

### Query identifier

The requirement for adding metrics is to have each query to have unique identifier.
Identifier is used to update the metric later when changed.

```yaml
- group: Response metrics (NGINX Ingress)
  metrics:
  - title: "Throughput"
    y_label: "Requests / Sec"
    queries:
    - id: response_metrics_nginx_ingress_throughput_status_code
      query_range: 'sum(rate(nginx_upstream_responses_total{upstream=~"%{kube_namespace}-%{ci_environment_slug}-.*"}[2m])) by (status_code)'
      unit: req / sec
      label: Status Code
```

### Update existing metrics

After you add or change existing _common_ metric you have to create a new database migration that will query and update all existing metrics.

**Note: If a query metric (which is identified by `id:`) is removed it will not be removed from database by default.**
**You might want to add additional database migration that makes a decision what to do with removed one.**
**For example: you might be interested in migrating all dependent data to a different metric.**

```ruby
class ImportCommonMetrics < ActiveRecord::Migration
  require_relative '../importers/common_metrics_importer.rb'

  DOWNTIME = false

  def up
    Importers::CommonMetricsImporter.new.execute
  end

  def down
    # no-op
  end
end
```
