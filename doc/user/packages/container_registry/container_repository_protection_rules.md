---
stage: Container
group: Container Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
gitlab_dedicated: yes
title: Protected container repositories
description: Protected container repositories in GitLab limit which user roles can push or delete images.
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/463669) in GitLab 16.7 [with a flag](../../../administration/feature_flags/_index.md) named `container_registry_protected_containers`. Disabled by default. This feature is an [experiment](../../../policy/development_stages_support.md).
- [Enabled on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/429074) in GitLab 17.8.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/480385) in GitLab 17.8. Feature flag `container_registry_protected_containers` removed.

{{< /history >}}

By default, any user with at least the Developer role can push and delete
container images to or from container repositories. Protect a container repository to restrict
which users can make changes to container images in your container repository.

When a container repository is protected, the default behavior enforces these restrictions on the container repository and its images:

| Action                                                                                   | Minimum role         |
|------------------------------------------------------------------------------------------|----------------------|
| Protect a container repository and its container images.                                 | The Maintainer role. |
| Push or create a new image in a container repository.                                    | The role set in the [**Minimum access level for push**](#create-a-container-repository-protection-rule) setting. |
| Push or update an existing image in a container repository.                              | The role set in the [**Minimum access level for push**](#create-a-container-repository-protection-rule) setting. |
| Push, create, or update an existing image in a container repository with a deploy token. | Not applicable. Deploy tokens can be used with non-protected repositories, but cannot be used to push images to protected container repositories, regardless of their scopes. |

You can use a wildcard (`*`) to protect multiple container repositories with the same container protection rule.
For example, you can protect different container repositories containing temporary container images built during a CI/CD pipeline.

The following table contains examples of container protection rules that match multiple container repositories:

| Path pattern with wildcard | Example matching container repositories |
|----------------------------|-----------------------------------------|
| `group/container-*`        | `group/container-prod`, `group/container-prod-sha123456789` |
| `group/*container`         | `group/container`, `group/prod-container`, `group/prod-sha123456789-container` |
| `group/*container*`        | `group/container`, `group/prod-sha123456789-container-v1` |

You can apply several protection rules to the same container repository.
A container repository is protected if at least one protection rule matches.

## Create a container repository protection rule

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/146523) in GitLab 16.10.

{{< /history >}}

Prerequisites:

- You must have at least the Maintainer role.

To create a protection rule:

1. On the left sidebar, select **Search or go to** and find your project. If you've [turned on the new navigation](../../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. Select **Settings** > **Packages and registries**.
1. Expand **Container registry**.
1. Under **Protected container repositories**, select **Add protection rule**.
1. Complete the fields:
   - **Repository path pattern** is a container repository path you want to protect.
     The pattern can include a wildcard (`*`).
   - **Minimum access level for push** describes the minimum access level required
     to push (create or update) to the protected container repository path.
1. Select **Protect**.

The protection rule is created and the container repository is now protected.

## Delete a container repository protection rule

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/146622) in GitLab 17.0.

{{< /history >}}

Prerequisites:

- You must have at least the Maintainer role.

To delete a protection rule:

1. On the left sidebar, select **Search or go to** and find your project. If you've [turned on the new navigation](../../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. Select **Settings** > **Packages and registries**.
1. Expand **Container registry**.
1. Under **Protected container repositories**, next to the protection rule you want to delete, select **Delete** ({{< icon name="remove" >}}).
1. On the confirmation dialog, select **Delete**.

The protection rule is deleted and the container repository is no longer protected.
