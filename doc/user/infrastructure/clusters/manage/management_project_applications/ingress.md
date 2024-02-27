---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Install Ingress with a cluster management project

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

> - [Introduced](https://gitlab.com/gitlab-org/project-templates/cluster-management/-/merge_requests/5) in GitLab 14.0.

Assuming you already have a project created from a
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
[chart](https://github.com/kubernetes/ingress-nginx/tree/master/charts/ingress-nginx)
for the available configuration options.
