---
stage: Package
group: Container Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Protected container tags
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed
**Status:** Experiment

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/505455) as an [experiment](../../../policy/development_stages_support.md) in GitLab 17.9 [with a flag](../../../administration/feature_flags.md) named `container_registry_protected_tags`. Disabled by default.

FLAG:
The availability of this feature is controlled by a feature flag.
For more information, see the history.
This feature is available for testing, but not ready for production use.

Control who can push and delete container tags in your project.

By default, users with the Developer role or higher can push and delete image tags in all project container repositories.
With tag protection rules, you can:

- Restrict pushing and deleting tags to specific user roles.
- Create up to 5 protection rules per project.
- Apply these rules across all container repositories in your project.

A tag is protected when at least one protection rule matches its name. If multiple rules match, the most restrictive rule applies.

Protected tags cannot be deleted by [cleanup policies](reduce_container_registry_storage.md#cleanup-policy).

## Prerequisites

Before you can use protected container tags:

- You must use the new container registry version:
  - GitLab.com: Enabled by default
  - GitLab Self-Managed: [Enable the metadata database](../../../administration/packages/container_registry_metadata_database.md)

## Create a protection rule

Prerequisites:

- You must have at least the Maintainer role

To create a protection rule:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > Packages and registries**.
1. Expand **Container registry**.
1. Under **Protected container tags**, select **Add protection rule**.
1. Complete the fields:
   - **Protect container tags matching**: Enter a regex pattern using [RE2 syntax](https://github.com/google/re2/wiki/Syntax). Patterns must not exceed 100 characters. See [regex pattern examples](#regex-pattern-examples).
   - **Minimum role allowed to push**: Select Maintainer, Owner, or Administrator.
   - **Minimum role allowed to delete**: Select Maintainer, Owner, or Administrator.
1. Select **Add rule**.

The protection rule is created and matching tags are protected.

## Regex pattern examples

Example patterns you can use to protect container tags:

| Pattern           | Description                                                              |
| ----------------- | ------------------------------------------------------------------------ |
| `.*`              | Protects all tags                                                        |
| `^v.*`            | Protects tags that start with "v" (like `v1.0.0`, `v2.1.0-rc1`)          |
| `\d+\.\d+\.\d+`   | Protects semantic version tags (like `1.0.0`, `2.1.0`)                   |
| `^latest$`        | Protects the `latest` tag                                                |
| `.*-stable$`      | Protects tags that end with "-stable" (like `1.0-stable`, `main-stable`) |
| `stable\|release` | Protects tags that contain "stable" or "release" (like `1.0-stable`) |

## Delete a protection rule

Prerequisites:

- You must have at least the Maintainer role

To delete a protection rule:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > Packages and registries**.
1. Expand **Container registry**.
1. Under **Protected container tags**, next to the protection rule you want to delete, select **Delete** (**{remove}**).
1. When prompted for confirmation, select **Delete**.

The protection rule is deleted and matching tags are no longer protected.

## Propagation delay

Rule changes rely on JWT tokens to propagate between services. As a result, changes to protection rules and user access roles might take effect only after current JWT tokens expire. The delay equals the [configured token duration](../../../administration/packages/container_registry.md#increase-token-duration):

- Default: 5 minutes
- GitLab.com: [15 minutes](../../gitlab_com/_index.md#gitlab-container-registry)

Most container registry clients (including Docker, the GitLab UI, and the API) request a new token for each operation, but custom clients might retain a token for its full validity period.

## Image manifest deletions

The GitLab UI and API do not support direct image manifest deletions.
Through direct container registry API calls, manifest deletions affect all associated tags.

To ensure tag protection, direct manifest deletion requests are only allowed when:

- Tag protection is disabled
- The user has permission to delete any protected tags
