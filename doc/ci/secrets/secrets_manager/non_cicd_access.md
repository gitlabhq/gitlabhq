---
stage: Software Supply Chain Security
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Access secrets from non-CI/CD workloads
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Status: Beta

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/594090) in GitLab 19.2 [with a flag](../../../administration/feature_flags/_index.md) named `secrets_manager_api_access`. Disabled by default.

{{< /history >}}

CI/CD jobs read [GitLab Secrets Manager](_index.md) secrets through the GitLab Runner.
Other workloads can read secrets through the [Secrets Manager API](../../../api/secrets_manager.md).
Examples include Kubernetes applications and infrastructure as code tools.

Reads go directly to the OpenBao backend, so secret availability does not depend on the GitLab application.

## Access token flow

1. A client authenticates to GitLab with a personal access token, a service account token,
   or a project or group access token.
1. The client calls the Secrets Manager API to mint a short-lived access token.
   The response includes the token and the OpenBao connection details.
1. The client presents the token to the OpenBao backend to read the secret value.

The access token expires after 5 minutes.
The client can use it with any [HashiCorp Vault](https://developer.hashicorp.com/vault) compatible client,
because OpenBao implements the Vault API.

## Prerequisites

- Secrets Manager must be enabled for the project or group.
- The caller must have at least the Reporter role.
- To read a secret value, the caller must be granted the read value permission for that secret.
  The Reporter role alone does not expose secret values.

## Read a secret

1. Mint an access token for the project:

   ```shell
   curl --request POST \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/projects/1/secrets_manager/access_token"
   ```

   The response includes a `provider.vault` object with the `server`, `namespace`, `path`,
   and `auth` details, and a short-lived `token`.

1. Use the returned token to authenticate to OpenBao and read the secret.
   Provide the `token` to the JWT authentication method at the `auth.jwt.path` mount with the `auth.jwt.role` role,
   then read the secret from the key-value engine at `path`.

For the full request and response format, see the [Secrets Manager API](../../../api/secrets_manager.md).

## Use with the External Secrets Operator

The [External Secrets Operator](https://external-secrets.io) can sync GitLab secrets into Kubernetes secrets
through its HashiCorp Vault provider.
A workload in the cluster keeps a fresh access token in a Kubernetes secret.
The operator reads that token to authenticate to OpenBao.

A validated configuration example is proposed in [issue 602550](https://gitlab.com/gitlab-org/gitlab/-/issues/602550).
A native Kubernetes integration is proposed in [epic 20382](https://gitlab.com/groups/gitlab-org/-/epics/20382).

## Use with Terraform

A Terraform or OpenTofu configuration can read GitLab secrets as a data source.
It mints an access token, then reads from OpenBao with the standard Vault provider.

A native GitLab Terraform provider integration is proposed in [epic 21177](https://gitlab.com/groups/gitlab-org/-/epics/21177).
