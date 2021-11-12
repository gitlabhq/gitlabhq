---
stage: Protect
group: Container Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Install Fluentd with a cluster management project **(FREE)**

> [Introduced](https://gitlab.com/gitlab-org/project-templates/cluster-management/-/merge_requests/5) in GitLab 14.0.

Assuming you already have a [Cluster management project](../../../../../user/clusters/management_project.md) created from a
[management project template](../../../../../user/clusters/management_project_template.md), to install Fluentd you should
uncomment this line from your `helmfile.yaml`:

```yaml
  - path: applications/fluentd/helmfile.yaml
```

You can also review the default values set for this chart in the
[`values.yaml`](https://github.com/helm/charts/blob/master/stable/fluentd/values.yaml) file.

You can customize the installation of Fluentd by defining
`applications/fluentd/values.yaml` file in your cluster management
project. Refer to the
[configuration chart](https://github.com/helm/charts/tree/master/stable/fluentd#configuration)
for the current development release of Fluentd for all available configuration options.

The configuration chart link points to the current development release, which
may differ from the version you have installed. To ensure compatibility, switch
to the specific branch or tag you are using.
