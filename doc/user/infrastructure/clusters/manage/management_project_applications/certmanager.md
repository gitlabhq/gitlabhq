---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Install cert-manager with a cluster management project
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

Assuming you already have a project created from a
[management project template](../../../../clusters/management_project_template.md), to install cert-manager you should
uncomment this line from your `helmfile.yaml`:

```yaml
  - path: applications/cert-manager/helmfile.yaml
```

And update the `applications/cert-manager/helmfile.yaml` with a valid email address.

```yaml
  values:
    - letsEncryptClusterIssuer:
        #
        # IMPORTANT: This value MUST be set to a valid email.
        #
        email: example@example.com
```

NOTE:
If your Kubernetes version is earlier than 1.20 and you are
[migrating from GitLab Managed Apps to a cluster management project](../../../../clusters/migrating_from_gma_to_project_template.md),
then you can instead use `- path: applications/cert-manager-legacy/helmfile.yaml` to
take over an existing release of cert-manager v0.10.

cert-manager:

- Is installed by default into the `gitlab-managed-apps` namespace of your cluster.
- Includes a
  [Let's Encrypt `ClusterIssuer`](https://cert-manager.io/docs/configuration/acme/) enabled by
  default. In the `certmanager-issuer` release, the issuer requires a valid email address
  for `letsEncryptClusterIssuer.email`. Let's Encrypt uses this email address to
  contact you about expiring certificates and issues related to your account.
- Can be customized in `applications/cert-manager/helmfile.yaml` by passing custom
  `values` to the `certmanager` release. Refer to the
  [chart](https://github.com/jetstack/cert-manager) for the available
  configuration options.
