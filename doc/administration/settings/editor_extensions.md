---
stage: Create
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Configure GitLab Editor Extensions including Visual Studio Code, JetBrains IDEs, Visual Studio, Eclipse and Neovim.
title: Configure Editor Extensions
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Configure Editor Extensions settings for your GitLab instance.

## Require a minimum language server version

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/541744) in GitLab 18.1 [with a flag](../feature_flags/_index.md) named `enforce_language_server_version`. Disabled by default.

{{< /history >}}

{{< alert type="flag" >}}

On GitLab Self-Managed, by default this feature is not available. To make it available, an administrator can [enable the feature flag](../feature_flags/_index.md) named `enforce_language_server_version`.
On GitLab.com, this feature is available but can be configured by GitLab.com administrators only.
On GitLab Dedicated, this feature is available.

{{< /alert >}}

By default, any GitLab Language Server version can connect to your GitLab instance when
personal access tokens are enabled. To block requests from clients on older versions,
configure a minimum language server version. Clients older than the minimum allowed
Language Server version receive an API error.

Prerequisites:

- You must be an administrator.

  ```ruby
  # For a specific user
  Feature.enable(:enforce_language_server_version, User.find(1))

  # For this GitLab instance
  Feature.enable(:enforce_language_server_version)
  ```

To enforce a minimum GitLab Language Server version:

1. On the left sidebar, at the bottom, select **Admin**.
1. On the left sidebar, select **Settings > General**.
1. Expand **Editor Extensions**.
1. Check **Language Server restrictions enabled**.
1. Under **Minimum GitLab Language Server client version**, enter a valid GitLab Language Server version.

To allow any GitLab Language Server clients:

1. On the left sidebar, at the bottom, select **Admin**.
1. On the left sidebar, select **Settings > General**.
1. Expand **Editor Extensions**.
1. Uncheck **Language Server restrictions enabled**.
1. Under **Minimum GitLab Language Server client version**, enter a valid GitLab Language Server version.

{{< alert type="note" >}}

Allowing all requests is not recommended. It can cause incompatibility if your
GitLab version is ahead of your extension version. You should update your extensions
to receive the latest feature improvements, bug fixes, and security fixes.

{{< /alert >}}
