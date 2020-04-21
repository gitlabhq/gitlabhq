# Prometheus integration

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/8935) in GitLab 9.0.

GitLab offers powerful integration with [Prometheus](https://prometheus.io) for monitoring key metrics of your apps, directly within GitLab.
Metrics for each environment are retrieved from Prometheus, and then displayed
within the GitLab interface.

![Environment Dashboard](img/prometheus_dashboard.png)

There are two ways to set up Prometheus integration, depending on where your apps are running:

- For deployments on Kubernetes, GitLab can automatically [deploy and manage Prometheus](#managed-prometheus-on-kubernetes).
- For other deployment targets, simply [specify the Prometheus server](#manual-configuration-of-prometheus).

Once enabled, GitLab will automatically detect metrics from known services in the [metric library](#monitoring-cicd-environments). You can also [add your own metrics](#adding-custom-metrics).

## Enabling Prometheus Integration

### Managed Prometheus on Kubernetes

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/issues/28916) in GitLab 10.5.

GitLab can seamlessly deploy and manage Prometheus on a [connected Kubernetes cluster](../clusters/index.md), making monitoring of your apps easy.

#### Requirements

- A [connected Kubernetes cluster](../clusters/index.md)
- Helm Tiller [installed by GitLab](../clusters/index.md#installing-applications)

#### Getting started

Once you have a connected Kubernetes cluster with Helm installed, deploying a managed Prometheus is as easy as a single click.

1. Go to the **Operations > Kubernetes** page to view your connected clusters
1. Select the cluster you would like to deploy Prometheus to
1. Click the **Install** button to deploy Prometheus to the cluster

![Managed Prometheus Deploy](img/prometheus_deploy.png)

#### Getting metrics to display on the Metrics Dashboard

After completing the steps above, you will also need deployments in order to view the
**Operations > Metrics** page. Setting up [Auto DevOps](../../../topics/autodevops/index.md)
will help you to quickly create a deployment:

1. Navigate to your project's **Operations > Kubernetes** page, and ensure that,
   in addition to "Prometheus" and "Helm Tiller", you also have "Runner" and "Ingress"
   installed. Once "Ingress" is installed, copy its endpoint.
1. Navigate to your project's **Settings > CI/CD** page. In the Auto DevOps section,
   select a deployment strategy and save your changes.
1. On the same page, in the Variables section, add a variable named `KUBE_INGRESS_BASE_DOMAIN`
   with the value of the Ingress endpoint you have copied in the previous step. Leave the type
   as "Variable".
1. Navigate to your project's **CI/CD > Pipelines** page, and run a pipeline on any branch.
1. When the pipeline has run successfully, graphs will be available on the **Operations > Metrics** page.

![Monitoring Dashboard](img/prometheus_monitoring_dashboard_v12_8.png)

#### Using the Metrics Dashboard

##### Select an environment

The **Environment** dropdown box above the dashboard displays the list of all [environments](#monitoring-cicd-environments).
It enables you to search as you type through all environments and select the one you're looking for.

![Monitoring Dashboard Environments](img/prometheus_dashboard_environments_v12_8.png)

#### About managed Prometheus deployments

Prometheus is deployed into the `gitlab-managed-apps` namespace, using the [official Helm chart](https://github.com/helm/charts/tree/master/stable/prometheus). Prometheus is only accessible within the cluster, with GitLab communicating through the [Kubernetes API](https://kubernetes.io/docs/concepts/overview/kubernetes-api/).

The Prometheus server will [automatically detect and monitor](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#kubernetes_sd_config) nodes, pods, and endpoints. To configure a resource to be monitored by Prometheus, simply set the following [Kubernetes annotations](https://kubernetes.io/docs/concepts/overview/working-with-objects/annotations/):

- `prometheus.io/scrape` to `true` to enable monitoring of the resource.
- `prometheus.io/port` to define the port of the metrics endpoint.
- `prometheus.io/path` to define the path of the metrics endpoint. Defaults to `/metrics`.

CPU and Memory consumption is monitored, but requires [naming conventions](prometheus_library/kubernetes.md#specifying-the-environment) in order to determine the environment. If you are using [Auto DevOps](../../../topics/autodevops/index.md), this is handled automatically.

The [NGINX Ingress](../clusters/index.md#installing-applications) that is deployed by GitLab to clusters, is automatically annotated for monitoring providing key response metrics: latency, throughput, and error rates.

### Manual configuration of Prometheus

#### Requirements

Integration with Prometheus requires the following:

1. GitLab 9.0 or higher
1. Prometheus must be configured to collect one of the [supported metrics](prometheus_library/index.md)
1. Each metric must be have a label to indicate the environment
1. GitLab must have network connectivity to the Prometheus server

#### Getting started

Installing and configuring Prometheus to monitor applications is fairly straight forward.

1. [Install Prometheus](https://prometheus.io/docs/prometheus/latest/installation/)
1. Set up one of the [supported monitoring targets](prometheus_library/index.md)
1. Configure the Prometheus server to [collect their metrics](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#scrape_config)

#### Configuration in GitLab

The actual configuration of Prometheus integration within GitLab is very simple.
All you will need is the domain name or IP address of the Prometheus server you'd like
to integrate with.

1. Navigate to the [Integrations page](overview.md#accessing-integrations).
1. Click the **Prometheus** service.
1. Provide the domain name or IP address of your server, for example `http://prometheus.example.com/` or `http://192.0.2.1/`.
1. Click **Save changes**.

![Configure Prometheus Service](img/prometheus_service_configuration.png)

#### Thanos configuration in GitLab

You can configure [Thanos](https://thanos.io/) as a drop-in replacement for Prometheus
with GitLab. You will need the domain name or IP address of the Thanos server you'd like
to integrate with.

1. Navigate to the [Integrations page](overview.md#accessing-integrations).
1. Click the **Prometheus** service.
1. Provide the domain name or IP address of your server, for example `http://thanos.example.com/` or `http://192.0.2.1/`.
1. Click **Save changes**.

## Monitoring CI/CD Environments

Once configured, GitLab will attempt to retrieve performance metrics for any
environment which has had a successful deployment.

GitLab will automatically scan the Prometheus server for metrics from known servers like Kubernetes and NGINX, and attempt to identify individual environment. The supported metrics and scan process is detailed in our [Prometheus Metrics Library documentation](prometheus_library/index.md).

You can view the performance dashboard for an environment by [clicking on the monitoring button](../../../ci/environments.md#monitoring-environments).

### Adding custom metrics

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/3799) in [GitLab Premium](https://about.gitlab.com/pricing/) 10.6.
> - [Moved](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/28527) to [GitLab Core](https://about.gitlab.com/pricing/) 12.10.

Custom metrics can be monitored by adding them on the monitoring dashboard page. Once saved, they will be displayed on the environment performance dashboard provided that either:

- A [connected Kubernetes cluster](../clusters/add_remove_clusters.md) with the environment scope of `*` is used and [Prometheus installed on the cluster](#enabling-prometheus-integration)
- Prometheus is [manually configured](#manual-configuration-of-prometheus).

![Add New Metric](img/prometheus_add_metric.png)

A few fields are required:

- **Name**: Chart title
- **Type**: Type of metric. Metrics of the same type will be shown together.
- **Query**: Valid [PromQL query](https://prometheus.io/docs/prometheus/latest/querying/basics/).
- **Y-axis label**: Y axis title to display on the dashboard.
- **Unit label**: Query units, for example `req / sec`. Shown next to the value.

Multiple metrics can be displayed on the same chart if the fields **Name**, **Type**, and **Y-axis label** match between metrics. For example, a metric with **Name** `Requests Rate`, **Type** `Business`, and **Y-axis label** `rec / sec` would display on the same chart as a second metric with the same values. A **Legend label** is suggested if this feature used.

#### Query Variables

GitLab supports a limited set of [CI variables](../../../ci/variables/README.md) in the Prometheus query. This is particularly useful for identifying a specific environment, for example with `ci_environment_slug`. The supported variables are:

- `ci_environment_slug`
- `kube_namespace`
- `ci_project_name`
- `ci_project_namespace`
- `ci_project_path`
- `ci_environment_name`

NOTE: **Note:**
Variables for Prometheus queries must be lowercase.

There are 2 methods to specify a variable in a query or dashboard:

1. Variables can be specified using the [Liquid template format](https://shopify.dev/docs/liquid/reference/basics), for example `{{ci_environment_slug}}` ([added](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/20793) in GitLab 12.6).
1. You can also enclose it in quotation marks with curly braces with a leading percent, for example `"%{ci_environment_slug}"`. This method is deprecated though and support will be [removed in the next major release](https://gitlab.com/gitlab-org/gitlab/issues/37990).

#### Editing additional metrics from the dashboard

> [Introduced](https://gitlab.com/gitlab-org/gitlab/issues/208976) in GitLab 12.9.

You can edit existing additional custom metrics by clicking the **{ellipsis_v}** **More actions** dropdown and selecting **Edit metric**.

![Edit metric](img/prometheus_dashboard_edit_metric_link_v_12_9.png)

### Defining custom dashboards per project

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/issues/59974) in GitLab 12.1.

By default, all projects include a GitLab-defined Prometheus dashboard, which
includes a few key metrics, but you can also define your own custom dashboards.

You may create a new file from scratch or duplicate a GitLab-defined Prometheus
dashboard.

NOTE: **Note:**
The metrics as defined below do not support alerts, unlike
[custom metrics](#adding-custom-metrics).

#### Adding a new dashboard to your project

You can configure a custom dashboard by adding a new YAML file into your project's
`.gitlab/dashboards/` directory. In order for the dashboards to be displayed on
the project's **Operations > Metrics** page, the files must have a `.yml`
extension and should be present in the project's **default** branch.

For example:

1. Create `.gitlab/dashboards/prom_alerts.yml` under your repository's root
   directory with the following contents:

   ```yaml
   dashboard: 'Dashboard Title'
   panel_groups:
     - group: 'Group Title'
       panels:
       - type: area-chart
         title: "Chart Title"
         y_label: "Y-Axis"
         y_axis:
           format: number
           precision: 0
         metrics:
         - id: my_metric_id
           query_range: 'http_requests_total'
           label: "Instance: {{instance}}, method: {{method}}"
           unit: "count"
   ```

   The above sample dashboard would display a single area chart. Each file should
   define the layout of the dashboard and the Prometheus queries used to populate
   data.

1. Save the file, commit, and push to your repository. The file must be present in your **default** branch.
1. Navigate to your project's **Operations > Metrics** and choose the custom
   dashboard from the dropdown.

NOTE: **Note:**
Configuration files nested under subdirectories of `.gitlab/dashboards` are not
supported and will not be available in the UI.

#### Duplicating a GitLab-defined dashboard

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/issues/37238) in GitLab 12.7.
> - From [GitLab 12.8 onwards](https://gitlab.com/gitlab-org/gitlab/issues/39505), custom metrics are also duplicated when you duplicate a dashboard.

You can save a complete copy of a GitLab defined dashboard along with all custom metrics added to it.
Resulting `.yml` file can be customized and adapted to your project.
You can decide to save the dashboard `.yml` file in the project's **default** branch or in a
new branch.

1. Click **Duplicate dashboard** in the dashboard dropdown.

   NOTE: **Note:**
   You can duplicate only GitLab-defined dashboards.

1. Enter the file name and other information, such as the new commit's message, and click **Duplicate**.

If you select your **default** branch, the new dashboard becomes immediately available.
If you select another branch, this branch should be merged to your **default** branch first.

#### Dashboard YAML properties

Dashboards have several components:

- Panel groups, which comprise of panels.
- Panels, which support one or more metrics.

The following tables outline the details of expected properties.

**Dashboard properties:**

| Property | Type | Required | Description |
| ------ | ------ | ------ | ------ |
| `dashboard` | string | yes | Heading for the dashboard. Only one dashboard should be defined per file. |
| `panel_groups` | array | yes | The panel groups which should be on the dashboard. |

**Panel group (`panel_groups`) properties:**

| Property | Type | Required | Description |
| ------ | ------ | ------ | ------ |
| `group` | string | required | Heading for the panel group. |
| `priority` | number | optional, defaults to order in file | Order to appear on the dashboard. Higher number means higher priority, which will be higher on the page. Numbers do not need to be consecutive. |
| `panels` | array | required | The panels which should be in the panel group. |

**Panel (`panels`) properties:**

| Property | Type | Required | Description |
| ------ | ------ | ------ | ------- |
| `type` | enum | no, defaults to `area-chart` | Specifies the chart type to use, can be: `area-chart`, `line-chart` or `anomaly-chart`. |
| `title` | string | yes | Heading for the panel. |
| `y_label` | string | no, but highly encouraged | Y-Axis label for the panel. |
| `y_axis` | string | no | Y-Axis configuration for the panel. |
| `max_value` | number | no | Denominator value used for calculating [percentile based results](#percentile-based-results) |
| `weight` | number | no, defaults to order in file | Order to appear within the grouping. Lower number means higher priority, which will be higher on the page. Numbers do not need to be consecutive. |
| `metrics` | array | yes | The metrics which should be displayed in the panel. Any number of metrics can be displayed when `type` is `area-chart` or `line-chart`, whereas only 3 can be displayed when `type` is `anomaly-chart`. |

**Axis (`panels[].y_axis`) properties:**

| Property    | Type   | Required                      | Description                                                          |
| ----------- | ------ | ----------------------------- | -------------------------------------------------------------------- |
| `name`      | string | no, but highly encouraged     | Y-Axis label for the panel. Replaces `y_label` if set.               |
| `format`    | string | no, defaults to `engineering` | Unit format used. See the [full list of units](prometheus_units.md). |
| `precision` | number | no, defaults to `2`           | Number of decimal places to display in the number.                                          |                        |

**Metrics (`metrics`) properties:**

| Property | Type | Required | Description |
| ------ | ------ | ------ | ------ |
| `id` | string | no | Used for associating dashboard metrics with database records. Must be unique across dashboard configuration files. Required for [alerting](#setting-up-alerts-for-prometheus-metrics) (support not yet enabled, see [relevant issue](https://gitlab.com/gitlab-org/gitlab/-/issues/27980)). |
| `unit` | string | yes | Defines the unit of the query's return data. |
| `label` | string | no, but highly encouraged | Defines the legend-label for the query. Should be unique within the panel's metrics. Can contain time series labels as interpolated variables. |
| `query` | string | yes if `query_range` is not defined | Defines the Prometheus query to be used to populate the chart/panel. If defined, the `query` endpoint of the [Prometheus API](https://prometheus.io/docs/prometheus/latest/querying/api/) will be utilized. |
| `query_range` | string | yes if `query` is not defined | Defines the Prometheus query to be used to populate the chart/panel. If defined, the `query_range` endpoint of the [Prometheus API](https://prometheus.io/docs/prometheus/latest/querying/api/) will be utilized. |
| `step` | number | no, value is calculated if not defined | Defines query resolution step width in float number of seconds. Metrics on the same panel should use the same `step` value. |

##### Dynamic labels

Dynamic labels are useful when multiple time series are returned from a Prometheus query.

When a static label is used and a query returns multiple time series, then all the legend items will be labeled the same, which makes identifying each time series difficult:

```yaml
metrics:
  - id: my_metric_id
    query_range: 'http_requests_total'
    label: "Time Series"
    unit: "count"
```

This may render a legend like this:

![repeated legend label chart](img/prometheus_dashboard_repeated_label.png)

For labels to be more explicit, using variables that reflect time series labels is a good practice. The variables will be replaced by the values of the time series labels when the legend is rendered:

```yaml
metrics:
  - id: my_metric_id
    query_range: 'http_requests_total'
    label: "Instance: {{instance}}, method: {{method}}"
    unit: "count"
```

The resulting rendered legend will look like this:

![legend with label variables](img/prometheus_dashboard_label_variables.png)

There is also a shorthand value for dynamic dashboard labels that make use of only one time series label:

```yaml
metrics:
  - id: my_metric_id
    query_range: 'http_requests_total'
    label: "Method"
    unit: "count"
```

This works by lowercasing the value of `label` and, if there are more words separated by spaces, replacing those spaces with an underscore (`_`). The transformed value is then checked against the labels of the time series returned by the Prometheus query. If a time series label is found that is equal to the transformed value, then the label value will be used and rendered in the legend like this:

![legend with label shorthand variable](img/prometheus_dashboard_label_variable_shorthand.png)

#### Panel types for dashboards

The below panel types are supported in monitoring dashboards.

##### Area or Line Chart

To add an area chart panel type to a dashboard, look at the following sample dashboard file:

```yaml
dashboard: 'Dashboard Title'
panel_groups:
  - group: 'Group Title'
    panels:
      - type: area-chart # or line-chart
        title: 'Area Chart Title'
        y_label: "Y-Axis"
        y_axis:
          format: number
          precision: 0
        metrics:
          - id: area_http_requests_total
            query_range: 'http_requests_total'
            label: "Instance: {{instance}}, Method: {{method}}"
            unit: "count"
```

Note the following properties:

| Property | Type | Required | Description |
| ------ | ------ | ------ | ------ |
| type | string | no | Type of panel to be rendered. Optional for area panel types |
| query_range | string | required | For area panel types, you must use a [range query](https://prometheus.io/docs/prometheus/latest/querying/api/#range-queries) |

![area panel chart](img/prometheus_dashboard_area_panel_type_v12_8.png)

Starting in [version 12.8](https://gitlab.com/gitlab-org/gitlab/issues/202696), the y-axis values will automatically scale according to the data. Previously, it always started from 0.

##### Anomaly chart

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/16530) in GitLab 12.5.

To add an anomaly chart panel type to a dashboard, add a panel with *exactly* 3 metrics.

The first metric represents the current state, and the second and third metrics represent the upper and lower limit respectively:

```yaml
dashboard: 'Dashboard Title'
panel_groups:
  - group: 'Group Title'
    panels:
      - type: anomaly-chart
        title: "Chart Title"
        y_label: "Y-Axis"
        metrics:
          - id: anomaly_requests_normal
            query_range: 'http_requests_total'
            label: "# of Requests"
            unit: "count"
        metrics:
          - id: anomaly_requests_upper_limit
            query_range: 10000
            label: "Max # of requests"
            unit: "count"
        metrics:
          - id: anomaly_requests_lower_limit
            query_range: 2000
            label: "Min # of requests"
            unit: "count"
```

Note the following properties:

| Property | Type | Required | Description |
| ------ | ------ | ------ | ------ |
| type | string | required | Must be `anomaly-chart` for anomaly panel types |
| query_range | yes | required | For anomaly panel types, you must use a [range query](https://prometheus.io/docs/prometheus/latest/querying/api/#range-queries) in every metric. |

![anomaly panel type](img/prometheus_dashboard_anomaly_panel_type.png)

##### Bar chart

To add a bar chart to a dashboard, look at the following sample dashboard file:

```yaml
dashboard: 'Dashboard Title'
panel_groups:
  - group: 'Group title'
    panels:
      - type: bar
        title: "Http Handlers"
        x_label: 'Response Size'
        y_axis:
          name: "Handlers"
        metrics:
          - id: prometheus_http_response_size_bytes_bucket
            query_range: "sum(increase(prometheus_http_response_size_bytes_bucket[1d])) by (handler)"
            unit: 'Bytes'
```

Note the following properties:

| Property | Type | Required | Description |
| ------ | ------ | ------ | ------ |
| `type` | string | yes | Type of panel to be rendered. For bar chart types, set to `bar` |
| `query_range` | yes | yes | For bar chart, you must use a [range query](https://prometheus.io/docs/prometheus/latest/querying/api/#range-queries)

![bar chart panel type](img/prometheus_dashboard_bar_chart_panel_type_v12.10.png)

##### Column chart

To add a column panel type to a dashboard, look at the following sample dashboard file:

```yaml
dashboard: 'Dashboard Title'
panel_groups:
  - group: 'Group title'
    panels:
      - title: "Column"
        type: "column"
        metrics:
        - id: 1024_memory
          query: 'avg(sum(container_memory_usage_bytes{container_name!="POD",pod_name=~"^%{ci_environment_slug}-([^c].*|c([^a]|a([^n]|n([^a]|a([^r]|r[^y])))).*|)-(.*)",namespace="%{kube_namespace}"}) by (job)) without (job) / count(avg(container_memory_usage_bytes{container_name!="POD",pod_name=~"^%{ci_environment_slug}-([^c].*|c([^a]|a([^n]|n([^a]|a([^r]|r[^y])))).*|)-(.*)",namespace="%{kube_namespace}"}) without (job)) /1024/1024'
          unit: MB
          label: "Memory Usage"
```

Note the following properties:

| Property | Type | Required | Description |
| ------ | ------ | ------ | ------ |
| type | string | yes | Type of panel to be rendered. For column panel types, set to `column` |
| query_range | yes | yes | For column panel types, you must use a [range query](https://prometheus.io/docs/prometheus/latest/querying/api/#range-queries) |

![anomaly panel type](img/prometheus_dashboard_column_panel_type.png)

##### Stacked column

> [Introduced](https://gitlab.com/gitlab-org/gitlab/issues/30583) in GitLab 12.8.

To add a stacked column panel type to a dashboard, look at the following sample dashboard file:

```yaml
dashboard: 'Dashboard title'
priority: 1
panel_groups:
- group: 'Group Title'
  priority: 5
  panels:
  - type: 'stacked-column'
    title: "Stacked column"
    y_label: "y label"
    x_label: 'x label'
    metrics:
      - id: memory_1
        query_range: 'memory_query'
        label: "memory query 1"
        unit: "count"
        series_name: 'group 1'
      - id: memory_2
        query_range: 'memory_query_2'
        label: "memory query 2"
        unit: "count"
        series_name: 'group 2'

```

![stacked column panel type](img/prometheus_dashboard_stacked_column_panel_type_v12_8.png)

| Property | Type | Required | Description |
| ------ | ------ | ------ | ------ |
| `type` | string | yes | Type of panel to be rendered. For stacked column panel types, set to `stacked-column` |
| `query_range` | yes | yes | For stacked column panel types, you must use a [range query](https://prometheus.io/docs/prometheus/latest/querying/api/#range-queries) |

##### Single Stat

To add a single stat panel type to a dashboard, look at the following sample dashboard file:

```yaml
dashboard: 'Dashboard Title'
panel_groups:
  - group: 'Group Title'
    panels:
      - title: "Single Stat"
        type: "single-stat"
        metrics:
        - id: 10
          query: 'max(go_memstats_alloc_bytes{job="prometheus"})'
          unit: MB
          label: "Total"
```

Note the following properties:

| Property | Type | Required | Description |
| ------ | ------ | ------ | ------ |
| type | string | yes | Type of panel to be rendered. For single stat panel types, set to `single-stat` |
| query | string | yes | For single stat panel types, you must use an [instant query](https://prometheus.io/docs/prometheus/latest/querying/api/#instant-queries) |

![single stat panel type](img/prometheus_dashboard_single_stat_panel_type.png)

###### Percentile based results

> [Introduced](https://gitlab.com/gitlab-org/gitlab/issues/201946) in GitLab 12.8.

Query results sometimes need to be represented as a percentage value out of 100. You can use the `max_value` property at the root of the panel definition:

```yaml
dashboard: 'Dashboard Title'
panel_groups:
  - group: 'Group Title'
    panels:
      - title: "Single Stat"
        type: "single-stat"
        max_value: 100
        metrics:
        - id: 10
          query: 'max(go_memstats_alloc_bytes{job="prometheus"})'
          unit: '%'
          label: "Total"
```

For example, if you have a query value of `53.6`, adding `%` as the unit results in a single stat value of `53.6%`, but if the maximum expected value of the query is `120`, the value would be `44.6%`. Adding the `max_value` causes the correct percentage value to display.

##### Heatmaps

> [Introduced](https://gitlab.com/gitlab-org/gitlab/issues/30581) in GitLab 12.5.

To add a heatmap panel type to a dashboard, look at the following sample dashboard file:

```yaml
dashboard: 'Dashboard Title'
panel_groups:
  - group: 'Group Title'
    panels:
      - title: "Heatmap"
        type: "heatmap"
        metrics:
        - id: 10
          query: 'sum(rate(nginx_upstream_responses_total{upstream=~"%{kube_namespace}-%{ci_environment_slug}-.*"}[60m])) by (status_code)'
          unit: req/sec
          label: "Status code"
```

Note the following properties:

| Property | Type | Required | Description |
| ------ | ------ | ------ | ------ |
| type | string | yes | Type of panel to be rendered. For heatmap panel types, set to `heatmap` |
| query_range | yes | yes | For area panel types, you must use a [range query](https://prometheus.io/docs/prometheus/latest/querying/api/#range-queries) |

![heatmap panel type](img/heatmap_panel_type.png)

### View and edit the source file of a custom dashboard

> [Introduced](https://gitlab.com/gitlab-org/gitlab/issues/34779) in GitLab 12.5.

When viewing a custom dashboard of a project, you can view the original
`.yml` file by clicking on **Edit dashboard** button.

### Chart Context Menu

From each of the panels in the dashboard, you can access the context menu by clicking the **{ellipsis_v}** **More actions** dropdown box above the upper right corner of the panel to take actions related to the chart's data.

![Context Menu](img/panel_context_menu_v12_10.png)

The options are:

- [View logs](#view-logs-ultimate)
- [Download CSV](#downloading-data-as-csv)
- [Copy link to chart](#embedding-gitlab-managed-kubernetes-metrics)
- [Alerts](#setting-up-alerts-for-prometheus-metrics)

### Dashboard Annotations

> [Introduced](https://gitlab.com/gitlab-org/gitlab/issues/211330) in GitLab 12.10 (enabled by feature flag `metrics_dashboard_annotations`).

You can use **Metrics Dashboard Annotations** to mark any important events on
every metrics dashboard by adding annotations to it. While viewing a dashboard,
annotation entries assigned to the selected time range will be automatically
fetched and displayed on every chart within that dashboard. On mouse hover, each
annotation presents additional details, including the exact time of an event and
its description.

You can create annotations by making requests to the
[Metrics dashboard annotations API](../../../api/metrics_dashboard_annotations.md)

### View Logs **(ULTIMATE)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/issues/122013) in GitLab 12.8.

If you have [Logs](../clusters/kubernetes_pod_logs.md) enabled,
you can navigate from the charts in the dashboard to view Logs by
clicking on the context menu in the upper-right corner.

If you use the **Timeline zoom** function at the bottom of the chart, logs will narrow down to the time range you selected.

### Timeline zoom and URL sharing

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/198910) in GitLab 12.8.

You can use the **Timeline zoom** function at the bottom of a chart to zoom in
on a date and time of your choice. When you click and drag the sliders to select
a different beginning or end date of data to display, GitLab adds your selected start
and end times to the URL, enabling you to share specific timeframes more easily.

### Downloading data as CSV

Data from Prometheus charts on the metrics dashboard can be downloaded as CSV.

### Setting up alerts for Prometheus metrics

#### Managed Prometheus instances

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/6590) in [GitLab Ultimate](https://about.gitlab.com/pricing/) 11.2 for [custom metrics](#adding-custom-metrics), and 11.3 for [library metrics](prometheus_library/metrics.md).

For managed Prometheus instances using auto configuration, alerts for metrics [can be configured](#adding-custom-metrics) directly in the performance dashboard.

To set an alert:

1. Click on the ellipsis icon in the top right corner of the metric you want to create the alert for.
1. Choose **Alerts**
1. Set threshold and operator.
1. Click **Add** to save and activate the alert.

![Adding an alert](img/prometheus_alert.png)

To remove the alert, click back on the alert icon for the desired metric, and click **Delete**.

#### External Prometheus instances

>- [Introduced](https://gitlab.com/gitlab-org/gitlab/issues/9258) in [GitLab Ultimate](https://about.gitlab.com/pricing/) 11.8.
>- [Moved](https://gitlab.com/gitlab-org/gitlab/issues/42640) to [GitLab Core](https://about.gitlab.com/pricing/) in 12.10.

For manually configured Prometheus servers, a notify endpoint is provided to use with Prometheus webhooks. If you have manual configuration enabled, an **Alerts** section is added to **Settings > Integrations > Prometheus**. This contains the *URL* and *Authorization Key*. The **Reset Key** button will invalidate the key and generate a new one.

![Prometheus service configuration of Alerts](img/prometheus_service_alerts.png)

To send GitLab alert notifications, copy the *URL* and *Authorization Key* into the [`webhook_configs`](https://prometheus.io/docs/alerting/configuration/#webhook_config) section of your Prometheus Alertmanager configuration:

```yaml
receivers:
  name: gitlab
  webhook_configs:
  - http_config:
      bearer_token: 9e1cbfcd546896a9ea8be557caf13a76
    send_resolved: true
    url: http://192.168.178.31:3001/root/manual_prometheus/prometheus/alerts/notify.json
  ...
```

In order for GitLab to associate your alerts with an [environment](../../../ci/environments.md), you need to configure a `gitlab_environment_name` label on the alerts you set up in Prometheus. The value of this should match the name of your Environment in GitLab.

### Taking action on incidents **(ULTIMATE)**

>- [Introduced](https://gitlab.com/gitlab-org/gitlab/issues/4925) in [GitLab Ultimate](https://about.gitlab.com/pricing/) 11.11.
>- [From GitLab Ultimate 12.5](https://gitlab.com/gitlab-org/gitlab/issues/13401), when GitLab receives a recovery alert, it will automatically close the associated issue.

Alerts can be used to trigger actions, like open an issue automatically (enabled by default since `12.1`). To configure the actions:

1. Navigate to your project's **Settings > Operations > Incidents**.
1. Enable the option to create issues.
1. Choose the [issue template](../description_templates.md) to create the issue from.
1. Optionally, select whether to send an email notification to the developers of the project.
1. Click **Save changes**.

Once enabled, an issue will be opened automatically when an alert is triggered which contains values extracted from [alert's payload](https://prometheus.io/docs/alerting/configuration/#webhook_config
):

- Issue author: `GitLab Alert Bot`
- Issue title: Extract from `annotations/title`, `annotations/summary` or `labels/alertname`
- Alert `Summary`: A list of properties
  - `starts_at`: Alert start time via `startsAt`
  - `full_query`: Alert query extracted from `generatorURL`
  - Optional list of attached annotations extracted from `annotations/*`
- Alert [GFM](../../markdown.md): GitLab Flavored Markdown from `annotations/gitlab_incident_markdown`

When GitLab receives a **Recovery Alert**, it will automatically close the associated issue. This action will be recorded as a system message on the issue indicated that it was closed automatically by the GitLab Alert bot.

To further customize the issue, you can add labels, mentions, or any other supported [quick action](../quick_actions.md) in the selected issue template, which will apply to all incidents. To limit quick actions or other information to only specific types of alerts, use the `annotations/gitlab_incident_markdown` field.

Since [version 12.2](https://gitlab.com/gitlab-org/gitlab-foss/issues/63373), GitLab will tag each incident issue with the `incident` label automatically. If the label does not yet exist, it will be created automatically as well.

If the metric exceeds the threshold of the alert for over 5 minutes, an email will be sent to all [Maintainers and Owners](../../permissions.md#project-members-permissions) of the project.

## Determining the performance impact of a merge

> - [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/10408) in GitLab 9.2.
> - GitLab 9.3 added the [numeric comparison](https://gitlab.com/gitlab-org/gitlab-foss/issues/27439) of the 30 minute averages.

Developers can view the performance impact of their changes within the merge
request workflow.

NOTE: **Note:**
Requires [Kubernetes](prometheus_library/kubernetes.md) metrics.

When a source branch has been deployed to an environment, a sparkline and
numeric comparison of the average memory consumption will appear. On the
sparkline, a dot indicates when the current changes were deployed, with up to 30 minutes of
performance data displayed before and after. The comparison shows the difference
between the 30 minute average before and after the deployment. This information
is updated after each commit has been deployed.

Once merged and the target branch has been redeployed, the metrics will switch
to show the new environments this revision has been deployed to.

Performance data will be available for the duration it is persisted on the
Prometheus server.

![Merge Request with Performance Impact](img/merge_request_performance.png)

## Embedding metric charts within GitLab Flavored Markdown

### Embedding GitLab-managed Kubernetes metrics

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/29691) in GitLab 12.2.

It is possible to display metrics charts within [GitLab Flavored Markdown](../../markdown.md#gitlab-flavored-markdown-gfm) fields such as issue or merge request descriptions. The maximum number of embedded charts allowed in a GitLab Flavored Markdown field is 100.

This can be useful if you are sharing an application incident or performance
metrics to others and want to have relevant information directly available.

NOTE: **Note:**
Requires [Kubernetes](prometheus_library/kubernetes.md) metrics.

To display metric charts, include a link of the form `https://<root_url>/<project>/-/environments/<environment_id>/metrics`:

![Embedded Metrics Markdown](img/embedded_metrics_markdown_v12_8.png)

GitLab unfurls the link as an embedded metrics panel:

![Embedded Metrics Rendered](img/embedded_metrics_rendered_v12_8.png)

You can also embed a single chart. To get a link to a chart, click the
**{ellipsis_v}** **More actions** menu in the upper right corner of the chart,
and select **Copy link to chart**, as shown in this example:

![Copy Link To Chart](img/copy_link_to_chart_v12_10.png)

The following requirements must be met for the metric to unfurl:

- The `<environment_id>` must correspond to a real environment.
- Prometheus must be monitoring the environment.
- The GitLab instance must be configured to receive data from the environment.
- The user must be allowed access to the monitoring dashboard for the environment ([Reporter or higher](../../permissions.md)).
- The dashboard must have data within the last 8 hours.

 If all of the above are true, then the metric will unfurl as seen below:

![Embedded Metrics](img/view_embedded_metrics_v12_10.png)

Metric charts may also be hidden:

![Show Hide](img/hide_embedded_metrics_v12_10.png)

### Embedding metrics in issue templates

It is also possible to embed either the default dashboard metrics or individual metrics in issue templates. For charts to render side-by-side, links to the entire metrics dashboard or individual metrics should be separated by either a comma or a space.

![Embedded Metrics in issue templates](img/embed_metrics_issue_template.png)

### Embedding metrics based on alerts in incident issues

For [GitLab-managed alerting rules](#setting-up-alerts-for-prometheus-metrics), the issue will include an embedded chart for the query corresponding to the alert. The chart displays an hour of data surrounding the starting point of the incident, 30 minutes before and after.

For [manually configured Prometheus instances](#manual-configuration-of-prometheus), a chart corresponding to the query can be included if these requirements are met:

- The alert corresponds to an environment managed through GitLab.
- The alert corresponds to a [range query](https://prometheus.io/docs/prometheus/latest/querying/api/#range-queries).
- The alert contains the required attributes listed in the chart below.

| Attributes | Required | Description |
| ---------- | -------- | ----------- |
| `annotations/gitlab_environment_name` | Yes | Name of the GitLab-managed environment corresponding to the alert |
| One of `annotations/title`, `annotations/summary`, `labels/alertname` | Yes | Will be used as the chart title |
| `annotations/gitlab_y_label` | No | Will be used as the chart's y-axis label |

### Embedding Cluster Health Charts **(ULTIMATE)**

> [Introduced](<https://gitlab.com/gitlab-org/gitlab/issues/40997>) in [GitLab Ultimate](https://about.gitlab.com/pricing/) 12.9.

[Cluster Health Metrics](../clusters/index.md#monitoring-your-kubernetes-cluster-ultimate) can also be embedded in [GitLab-flavored Markdown](../../markdown.md).

To embed a metric chart, include a link to that chart in the form `https://<root_url>/<project>/-/cluster/<cluster_id>?<query_params>` anywhere that GitLab-flavored Markdown is supported. To generate and copy a link to the chart, follow the instructions in the [Cluster Health Metric documentation](../clusters/index.md#monitoring-your-kubernetes-cluster-ultimate).

The following requirements must be met for the metric to unfurl:

- The `<cluster_id>` must correspond to a real cluster.
- Prometheus must be monitoring the cluster.
- The user must be allowed access to the project cluster metrics.
- The dashboards must be reporting data on the [Cluster Health Page](../clusters/index.md#monitoring-your-kubernetes-cluster-ultimate)

 If the above requirements are met, then the metric will unfurl as seen below.

![Embedded Cluster Metric in issue descriptions](img/prometheus_cluster_health_embed_v12_9.png)

### Embedding Grafana charts

Grafana metrics can be embedded in [GitLab Flavored Markdown](../../markdown.md).

#### Embedding charts via Grafana Rendered Images

It is possible to embed live [Grafana](https://docs.gitlab.com/omnibus/settings/grafana.html) charts in issues, as a [direct linked rendered image](https://grafana.com/docs/grafana/latest/reference/share_panel/#direct-link-rendered-image).

The sharing dialog within Grafana provides the link, as highlighted below.

![Grafana Direct Linked Rendered Image](img/grafana_live_embed.png)

NOTE: **Note:**
For this embed to display correctly, the Grafana instance must be available to the target user, either as a public dashboard, or on the same network.

Copy the link and add an image tag as [inline HTML](../../markdown.md#inline-html) in your Markdown. You may tweak the query parameters as required. For instance, removing the `&from=` and `&to=` parameters will give you a live chart. Here is example markup for a live chart from GitLab's public dashboard:

```html
<img src="https://dashboards.gitlab.com/d/RZmbBr7mk/gitlab-triage?orgId=1&refresh=30s&var-env=gprd&var-environment=gprd&var-prometheus=prometheus-01-inf-gprd&var-prometheus_app=prometheus-app-01-inf-gprd&var-backend=All&var-type=All&var-stage=main&from=1580444107655&to=1580465707655"/>
```

This will render like so:

![Grafana dashboard embedded preview](img/grafana_embedded.png)

#### Embedding charts via integration with Grafana HTTP API

> [Introduced](https://gitlab.com/gitlab-org/gitlab/issues/31376) in GitLab 12.5.

Each project can support integration with one Grafana instance. This configuration allows a user to copy a link to a panel in Grafana, then paste it into a GitLab Markdown field. The chart will be rendered in the GitLab chart format.

Prerequisites for embedding from a Grafana instance:

1. The datasource must be a Prometheus instance.
1. The datasource must be proxyable, so the HTTP Access setting should be set to `Server`.

![HTTP Proxy Access](img/http_proxy_access_v12_5.png)

##### Setting up the Grafana integration

1. [Generate an Admin-level API Token in Grafana.](https://grafana.com/docs/grafana/latest/http_api/auth/#create-api-token)
1. In your GitLab project, navigate to **Settings > Operations > Grafana Authentication**.
1. To enable the integration, check the "Active" checkbox.
1. For "Grafana URL", enter the base URL of the Grafana instance.
1. For "API Token", enter the Admin API Token you just generated.
1. Click **Save Changes**.

##### Generating a link to a chart

1. In Grafana, navigate to the dashboard you wish to embed a panel from.
   ![Grafana Metric Panel](img/grafana_panel_v12_5.png)
1. In the upper-left corner of the page, select a specific value for each variable required for the queries in the chart.
   ![Select Query Variables](img/select_query_variables_v12_5.png)
1. In Grafana, click on a panel's title, then click **Share** to open the panel's sharing dialog to the **Link** tab. If you click the _dashboard's_ share panel instead, GitLab will attempt to embed the first supported panel on the dashboard (if available).
1. If your Prometheus queries use Grafana's custom template variables, ensure that "Template variables" option is toggled to **On**. Of Grafana global template variables, only `$__interval`, `$__from`, and `$__to` are currently supported. Toggle **On** the "Current time range" option to specify the time range of the chart. Otherwise, the default range will be the last 8 hours.
   ![Grafana Sharing Dialog](img/grafana_sharing_dialog_v12_5.png)
1. Click **Copy** to copy the URL to the clipboard.
1. In GitLab, paste the URL into a Markdown field and save. The chart will take a few moments to render.
   ![GitLab Rendered Grafana Panel](img/rendered_grafana_embed_v12_5.png)

## Troubleshooting

When troubleshooting issues with a managed Prometheus app, it is often useful to
[view the Prometheus UI](../../../development/prometheus.md#access-the-ui-of-a-prometheus-managed-application-in-kubernetes).

### "No data found" error on Metrics dashboard page

If the "No data found" screen continues to appear, it could be due to:

- No successful deployments have occurred to this environment.
- Prometheus does not have performance data for this environment, or the metrics
  are not labeled correctly. To test this, connect to the Prometheus server and
  [run a query](prometheus_library/kubernetes.md#metrics-supported), replacing `$CI_ENVIRONMENT_SLUG`
  with the name of your environment.
- You may need to re-add the GitLab predefined common metrics. This can be done by running the [import common metrics Rake task](../../../administration/raketasks/maintenance.md#import-common-metrics).
