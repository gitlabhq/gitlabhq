---
stage: Monitor
group: APM
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# Using Variables

## Query Variables

Variables can be specified using double curly braces, such as `"{{ci_environment_slug}}"` ([added](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/20793) in GitLab 12.7).

Support for the `"%{ci_environment_slug}"` format was
[removed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/31581) in GitLab 13.0.
Queries that continue to use the old format will show no data.

## Predefined variables

GitLab supports a limited set of [CI variables](../../../ci/variables/README.md) in the Prometheus query. This is particularly useful for identifying a specific environment, for example with `ci_environment_slug`. The supported variables are:

- `ci_environment_slug`
- `kube_namespace`
- `ci_project_name`
- `ci_project_namespace`
- `ci_project_path`
- `ci_environment_name`
- `__range`

NOTE: **Note:**
Variables for Prometheus queries must be lowercase.

### __range

The `__range` variable is useful in Prometheus
[range vector selectors](https://prometheus.io/docs/prometheus/latest/querying/basics/#range-vector-selectors).
Its value is the total number of seconds in the dashboard's time range.
For example, if the dashboard time range is set to 8 hours, the value of
`__range` is `28800s`.

## User-defined variables

[Variables can be defined](../../../operations/metrics/dashboards/yaml.md#templating-templating-properties) in a custom dashboard YAML file.

## Query Variables from URL

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/214500) in GitLab 13.0.

GitLab supports setting custom variables through URL parameters. Surround the variable
name with double curly braces (`{{example}}`) to interpolate the variable in a query:

```plaintext
avg(sum(container_memory_usage_bytes{container_name!="{{pod}}"}) by (job)) without (job)  /1024/1024/1024'
```

The URL for this query would be:

```plaintext
http://gitlab.com/<user>/<project>/-/environments/<environment_id>/metrics?dashboard=.gitlab%2Fdashboards%2Fcustom.yml&pod=POD
```
