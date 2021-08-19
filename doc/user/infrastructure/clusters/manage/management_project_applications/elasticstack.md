---
stage: Monitor
group: Monitor
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Install Elastic Stack with a cluster management project

> [Introduced](https://gitlab.com/gitlab-org/project-templates/cluster-management/-/merge_requests/5) in GitLab 14.0.

Assuming you already have a [Cluster management project](../../../../../user/clusters/management_project.md) created from a
[management project template](../../../../../user/clusters/management_project_template.md), to install Elastic Stack you should
uncomment this line from your `helmfile.yaml`:

```yaml
  - path: applications/elastic-stack/helmfile.yaml
```

Elastic Stack is installed by default into the `gitlab-managed-apps` namespace of your cluster.

You can check the default
[`values.yaml`](https://gitlab.com/gitlab-org/project-templates/cluster-management/-/blob/master/applications/elastic-stack/values.yaml)
we set for this chart.

You can customize the installation of Elastic Stack by updating the
`applications/elastic-stack/values.yaml` file in your cluster
management project. Refer to the
[chart](https://gitlab.com/gitlab-org/charts/elastic-stack) for all
available configuration options.

Support for installing the Elastic Stack managed application is provided by the
GitLab APM group. If you run into unknown issues,
[open a new issue](https://gitlab.com/gitlab-org/gitlab/-/issues/new), and ping at
least 2 people from the [APM group](https://about.gitlab.com/handbook/product/categories/#apm-group).
