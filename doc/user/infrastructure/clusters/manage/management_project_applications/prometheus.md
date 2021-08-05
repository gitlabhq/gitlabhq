---
stage: Monitor
group: Monitor
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Install Prometheus with a cluster management project

> [Introduced](https://gitlab.com/gitlab-org/project-templates/cluster-management/-/merge_requests/5) in GitLab 14.0.

[Prometheus](https://prometheus.io/docs/introduction/overview/) is an
open-source monitoring and alerting system for supervising your
deployed applications.

Assuming you already have a [Cluster management project](../../../../../user/clusters/management_project.md) created from a
[management project template](../../../../../user/clusters/management_project_template.md), to install Prometheus you should
uncomment this line from your `helmfile.yaml`:

```yaml
  - path: applications/prometheus/helmfile.yaml
```

You can customize the installation of Prometheus by updating the
`applications/prometheus/values.yaml` file in your cluster
management project. Refer to the
[Configuration section](https://github.com/helm/charts/tree/master/stable/prometheus#configuration)
of the Prometheus chart's README for the available configuration options.

Support for installing the Prometheus managed application is provided by the
GitLab APM group. If you run into unknown issues,
[open a new issue](https://gitlab.com/gitlab-org/gitlab/-/issues/new), and ping at
least 2 people from the [APM group](https://about.gitlab.com/handbook/product/categories/#apm-group).
