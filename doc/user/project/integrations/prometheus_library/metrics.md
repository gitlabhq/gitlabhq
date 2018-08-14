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

We strive to support the 2-4 most important metrics for each common system service that supports Prometheus. If you are looking for support for a particular exporter which has not yet been added to the library, additions can be made [to the `additional_metrics.yml`](https://gitlab.com/gitlab-org/gitlab-ce/blob/master/config/prometheus/additional_metrics.yml) file.

> Note: The library is only for monitoring public, common, system services which all customers can benefit from. Support for monitoring [customer proprietary metrics](https://gitlab.com/gitlab-org/gitlab-ee/issues/2273) will be added in a subsequent release.
