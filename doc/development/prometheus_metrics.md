# Working with Prometheus Metrics

## Adding to the library

We strive to support the 2-4 most important metrics for each common system service that supports Prometheus. If you are looking for support for a particular exporter which has not yet been added to the library, additions can be made [to the `common_metrics.yml`](https://gitlab.com/gitlab-org/gitlab-ce/blob/master/config/prometheus/common_metrics.yml) file.

### Query identifier

The requirement for adding a new metrics is to make each query to have an unique identifier.
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
