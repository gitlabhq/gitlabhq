---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Access token scopes
description: Permissions granted by each scope for personal, group, and project access tokens.
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- Personal access tokens can no longer access container or package registries
  [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/387721) in GitLab 16.0.
- `k8s_proxy` [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/422408) in GitLab 16.4
  [with a feature flag](../../administration/feature_flags/_index.md) named `k8s_proxy_pat`. Enabled by default.
- Feature flag `k8s_proxy_pat`
  [removed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/131518) in GitLab 16.5.
- `read_service_ping`
  [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/42692#note_1222832412) in GitLab 17.1.
  Personal access tokens only.
- `manage_runner` [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/460721) in GitLab 17.1.
- `self_rotate` [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/178111)
  in GitLab 17.9. Enabled by default.

{{< /history >}}

Scopes define what an access token can do at a specific organizational level. Each scope grants a
specific set of permissions.

The token type determines a token's reach:

- A personal access token can access all groups and projects available to the user.
- A group access token can access the subgroups and projects in its group.
- A project access token can access only its project.

To restrict a personal access token to specific resources and permissions, see
[fine-grained personal access tokens](../../auth/tokens/fine_grained_access_tokens.md).

| Scope | Token availability | Description |
|-------|------------|-------------|
| `api` | Personal, group, project | Grants complete read and write access to the API for the token's scope. Includes the [container registry](../../user/packages/container_registry/_index.md), the [dependency proxy](../../user/packages/dependency_proxy/_index.md), and the [package registry](../../user/packages/package_registry/_index.md). <sup>1</sup> |
| `read_api` | Personal, group, project | Grants read access to the API for the token's scope. For a personal access token, includes the container registry and the package registry; for group and project access tokens, the package registry only. |
| `read_repository` | Personal, group, project | Grants read access (pull) to repositories for the token's scope: private projects for a personal access token, all repositories in the group for a group access token, or the repository in the project for a project access token. Uses Git-over-HTTP or the [repository files API](../../api/repository_files.md). |
| `write_repository` | Personal, group, project | Grants read and write access (pull and push) to repositories for the token's scope: private projects for a personal access token, all repositories in the group for a group access token, or the repository in the project for a project access token. Uses Git-over-HTTP. Does not support API authentication. |
| `read_registry` | Personal, group, project | Grants read access (pull) to [container registry](../../user/packages/container_registry/_index.md) images when authorization is required. Available only when the container registry is enabled. The privacy condition differs by token type: it applies to a personal access token when a project is private, to a group access token when any project in the group is private, and to a project access token when the project is private. |
| `write_registry` | Personal, group, project | Grants write access (push) to [container registry](../../user/packages/container_registry/_index.md) images. Available only when the container registry is enabled. For group and project access tokens, you must also include the `read_registry` scope to push images. |
| `self_rotate` | Personal, group, project | Grants permission to rotate this token. Cannot rotate other tokens. To rotate personal access tokens, see the [personal access token API](../../api/personal_access_tokens.md#rotate-a-personal-access-token). |
| `read_virtual_registry` | Personal, group | Grants read access (pull) to container images through the [dependency proxy](../../user/packages/dependency_proxy/_index.md). Available only when the dependency proxy is enabled. <sup>2</sup> |
| `write_virtual_registry` | Personal, group | Grants read and write access (pull, push, and delete) to container images through the [dependency proxy](../../user/packages/dependency_proxy/_index.md). Available only when the dependency proxy is enabled. <sup>2</sup> |
| `create_runner` | Personal, group, project | Grants permission to create runners for the token's scope. |
| `manage_runner` | Personal, group, project | Grants permission to manage runners for the token's scope. |
| `ai_features` | Personal, group, project | Grants permission to perform API actions for GitLab Duo, the Code Suggestions API, and the GitLab Duo Chat API. Designed to work with the GitLab Duo Plugin for JetBrains. For all other extensions, see the individual extension documentation. Does not work for GitLab Self-Managed versions 16.5, 16.6, and 16.7. On GitLab Self-Managed and GitLab Dedicated, this scope is only available when GitLab Duo is enabled. |
| `k8s_proxy` | Personal, group, project | Grants permission to perform Kubernetes API calls through the agent for Kubernetes. |
| `admin_mode` | Personal | Grants permission to perform API actions when [Admin Mode](../../administration/settings/sign_in_restrictions.md#admin-mode) is enabled. Available only to administrators on GitLab Self-Managed instances. |
| `read_service_ping` | Personal | Grants access to download the Service Ping payloads through the API when authenticated as an administrator. |
| `sudo` | Personal | Grants permission to perform API actions as any user in the system, when authenticated as an administrator. |
| `read_user` | Personal | Grants read-only access to the authenticated user's profile through the `/user` API endpoint, which includes username, public email, and full name. Also grants access to read-only API endpoints under [`/users`](../../api/users.md). |

> [!warning]
> If you have turned on [external authorization](../../administration/settings/external_authorization.md),
> personal and project access tokens cannot access container or package registries. To restore
> access, turn off external authorization.

**Footnotes**:

1. For a personal access token, `api` also grants complete read and write access to the registry
   and repository through Git-over-HTTP. Group and project access tokens do not include this
   Git-over-HTTP clause.
1. For a personal access token, the virtual registry scopes apply only when a project is private
   and authorization is required. Group access tokens carry no such condition.

## Related topics

- [Personal access tokens](../../user/profile/personal_access_tokens.md)
- [Group access tokens](../../user/group/settings/group_access_tokens.md)
- [Project access tokens](../../user/project/settings/project_access_tokens.md)
- [Token overview](../../security/tokens/_index.md)
