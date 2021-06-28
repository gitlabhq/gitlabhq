---
stage: Monitor
group: Monitor
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Prometheus Metrics library **(FREE)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/8935) in GitLab 9.0.

GitLab offers automatic detection of select [Prometheus exporters](https://prometheus.io/docs/instrumenting/exporters/).

## Exporters

Currently supported exporters are:

- [Kubernetes](kubernetes.md)
- [NGINX](nginx.md)
- [NGINX Ingress Controller 0.9.0-0.15.x](nginx_ingress_vts.md)
- [NGINX Ingress Controller 0.16.0+](nginx_ingress.md)
- [HAProxy](haproxy.md)
- [Amazon Cloud Watch](cloudwatch.md)

We have tried to surface the most important metrics for each exporter, and
continue to add support for additional exporters in future releases. If you
would like to add support for other official exporters, contributions are welcome.

## Identifying Environments

GitLab retrieves performance data from the configured Prometheus server, and
attempts to identifying the presence of known metrics. Once identified, GitLab
then needs to be able to map the data to a particular environment.

In order to isolate and only display relevant metrics for a given environment,
GitLab needs a method to detect which labels are associated. To do that,
GitLab uses the defined queries and fills in the environment specific variables.
Typically this involves looking for the
[`$CI_ENVIRONMENT_SLUG`](../../../../ci/variables/index.md#predefined-cicd-variables),
but may also include other information such as the project's Kubernetes namespace.
Each search query is defined in the [exporter specific documentation](#exporters).
