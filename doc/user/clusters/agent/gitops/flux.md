---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Flux (Beta) **(FREE)**

Flux is a GitOps tool that helps you manage your Kubernetes clusters.
You can use Flux to:

- Keep your clusters in sync with your Git repositories.
- Reconcile code changes with your deployments.
- Manage your Flux installation itself with a bootstrap.

To get started, see the [Flux installation documentation](https://fluxcd.io/flux/installation).

Support for Flux is in [Beta](../../../../policy/alpha-beta-support.md#beta).

## Bootstrap installation

Use the Flux command [`bootstrap gitlab`](https://fluxcd.io/flux/installation/#gitlab-and-gitlab-enterprise)
to configure a Kubernetes cluster to manage itself from a Git repository.

You must authenticate your installation with either:

- Recommended. [A project access token](../../../project/settings/project_access_tokens.md).
- A [group access token](../../../group/settings/group_access_tokens.md).
- A [personal access token](../../../profile/personal_access_tokens.md).

Some Flux features like [automated image updates](https://fluxcd.io/flux/guides/image-update/) require
write access to the source repositories.

## GitOps repository structure

You should organize your repositories to meet the needs of your team. For detailed recommendations, see the Flux [repository structure documentation](https://fluxcd.io/flux/guides/repository-structure/).
