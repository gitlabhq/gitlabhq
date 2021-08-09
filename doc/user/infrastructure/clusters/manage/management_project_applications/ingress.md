---
stage: Configure
group: Configure
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Install Ingress with a cluster management project

> [Introduced](https://gitlab.com/gitlab-org/project-templates/cluster-management/-/merge_requests/5) in GitLab 14.0.

Assuming you already have a [Cluster management project](../../../../../user/clusters/management_project.md) created from a
[management project template](../../../../../user/clusters/management_project_template.md), to install Ingress you should
uncomment this line from your `helmfile.yaml`:

```yaml
  - path: applications/ingress/helmfile.yaml
```

Ingress is installed by default into the `gitlab-managed-apps` namespace
of your cluster.

You can customize the installation of Ingress by updating the
`applications/ingress/values.yaml` file in your cluster
management project. Refer to the
[chart](https://github.com/helm/charts/tree/master/stable/nginx-ingress)
for the available configuration options.

Support for installing the Ingress managed application is provided by the GitLab Configure group.
If you run into unknown issues, [open a new issue](https://gitlab.com/gitlab-org/gitlab/-/issues/new),
and ping at least 2 people from the
[Configure group](https://about.gitlab.com/handbook/product/categories/#configure-group).
