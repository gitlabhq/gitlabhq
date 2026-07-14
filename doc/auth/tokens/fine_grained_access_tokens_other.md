---
stage: Software Supply Chain Security
group: Authorization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Fine-grained permissions for Git and other operations
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/work_items/596613) in GitLab 19.2.

{{< /history >}}

A fine-grained personal access token can access only the resources and permissions you grant it.
To use one with Git and other operations, create a token and define its scope. For more information, see
[fine-grained personal access tokens](fine_grained_access_tokens.md).

In the following tables:

- **Resource** and **Permission** are the resource and permission to select when you create the
  token.
- **Access** is the boundary that must contain the target resource. A token scoped to a group also
  authorizes operations on the projects in that group.

## Git operations

A fine-grained personal access token used as the password for Git over HTTPS must have the
following permissions:

| Operation                          | Resource | Permission | Access        |
| ---------------------------------- | -------- | ---------- | ------------- |
| Clone or pull a project repository | Code     | Download   | Project       |
| Push to a project repository       | Code     | Push       | Project       |
| Clone or pull a wiki               | Wiki     | Read       | Project, Group <sup>1</sup> |
| Push to a wiki                     | Wiki     | Create     | Project, Group <sup>1</sup> |
| Clone or pull a snippet            | Snippet  | Read       | Project, User <sup>2</sup> |
| Push to a snippet                  | Snippet  | Update     | Project, User <sup>2</sup> |
| Download Git LFS objects           | Code     | Download   | Project       |
| Upload Git LFS objects             | Code     | Push       | Project       |

**Footnotes**:

1. Project wikis use the project boundary and group wikis use the group boundary.
1. Project snippets use the project boundary and personal snippets use the user boundary.

## Container registry

A fine-grained personal access token used to sign in to the
[container registry](../../user/packages/container_registry/authenticate_with_container_registry.md)
must have the following permissions:

| Operation                                     | Resource             | Permission | Access  |
| --------------------------------------------- | -------------------- | ---------- | ------- |
| Pull container images                         | Container Repository | Read       | Project |
| Delete container images and tags              | Container Repository | Delete     | Project |

> [!note]
> You cannot use fine-grained personal access tokens to push container images.

## Dependency proxy

A fine-grained personal access token used to sign in to the
[dependency proxy](../../user/packages/dependency_proxy/_index.md) must have the following
permissions:

| Operation                                     | Resource         | Permission | Access |
| --------------------------------------------- | ---------------- | ---------- | ------ |
| Pull container images through the dependency proxy | Dependency Proxy | Read  | Group  |

## Archive and release asset downloads

| Operation                                     | Resource | Permission | Access  |
| --------------------------------------------- | -------- | ---------- | ------- |
| Download a repository archive                 | Code     | Download   | Project |
| Download a release asset from a direct link   | Release  | Read       | Project |

## RSS and calendar feeds

A fine-grained personal access token used to authenticate RSS or iCalendar feed requests must have
the following permissions:

| Feed                                          | Resource              | Permission | Access               |
| --------------------------------------------- | --------------------- | ---------- | -------------------- |
| User activity                                 | Activity              | Read       | User                 |
| Project activity                              | Event                 | Read       | Project              |
| Group activity                                | Event                 | Read       | Group                |
| Project commits                               | Code                  | Read       | Project              |
| Project tags                                  | Code                  | Read       | Project              |
| Issues and work items, including calendars    | Work Item             | Read       | Project, Group, User |
| Merge requests                                | Merge Request         | Read       | Project, Group       |
| Your projects                                 | Project               | Read       | User                 |
| Personal access token expiration calendar     | Personal Access Token | Read       | User                 |

## Other operations

| Operation                                     | Resource         | Permission | Access         |
| --------------------------------------------- | ---------------- | ---------- | -------------- |
| Forward editor extension telemetry events     | Editor Telemetry | Create     | User           |
| Receive live comment updates over WebSocket   | Work Item        | Read       | Project, Group |
