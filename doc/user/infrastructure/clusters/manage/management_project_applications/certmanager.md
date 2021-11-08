---
stage: Configure
group: Configure
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Install cert-manager with a cluster management project **(FREE)**

> - [Introduced](https://gitlab.com/gitlab-org/project-templates/cluster-management/-/merge_requests/5) in GitLab 14.0.
> - Support for cert-manager v1.4 was [introduced](https://gitlab.com/gitlab-org/project-templates/cluster-management/-/merge_requests/69405) in GitLab 14.3.

Assuming you already have a [Cluster management project](../../../../../user/clusters/management_project.md) created from a
[management project template](../../../../../user/clusters/management_project_template.md), to install cert-manager you should
uncomment this line from your `helmfile.yaml`:

```yaml
  - path: applications/cert-manager-1-4/helmfile.yaml
```

NOTE:
We kept the `- path: applications/cert-manager/helmfile.yaml` with cert-manager v0.10 to facilitate
the [migration from GitLab Managed Apps to a cluster management project](../../../../clusters/migrating_from_gma_to_project_template.md).

cert-manager:

- Is installed by default into the `gitlab-managed-apps` namespace of your cluster.
- Can be installed with or without a default
  [Let's Encrypt `ClusterIssuer`](https://cert-manager.io/docs/configuration/acme/), which requires an
  email address to be specified. The email address is used by Let's Encrypt to
  contact you about expiring certificates and issues related to your account.

To install cert-manager in your cluster, configure your `applications/cert-manager-1-4/helmfile.yaml` to:

```yaml
certManager:
  installed: true
  letsEncryptClusterIssuer:
    installed: true
    email: "user@example.com"
```

Or without the default `ClusterIssuer`:

```yaml
certManager:
  installed: true
  letsEncryptClusterIssuer:
    installed: false
```

You can customize the installation of cert-manager by defining a
`.gitlab/managed-apps/cert-manager/values.yaml` file in your cluster
management project. Refer to the
[chart](https://github.com/jetstack/cert-manager) for the
available configuration options.
