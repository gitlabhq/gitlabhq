---
stage: Create
group: Remote Development
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Configure VS Code Extension Marketplace for features on the GitLab self-managed instance.
title: Configure VS Code Extension Marketplace
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

The VS Code Extension Marketplace provides you with access to extensions that enhance the
functionality of the [Web IDE](../../user/project/web_ide/_index.md) and
[Workspaces](../../user/workspace/_index.md) in GitLab. As an administrator, you can enable this
feature across your GitLab instance and configure which extension registry your users can access.

## Access VS Code Extension Marketplace settings

Prerequisites:

- You must be an administrator.

To access the VS Code Extension Marketplace settings:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > General**.
1. Expand **VS Code Extension Marketplace**.

## Enable with default extension registry

By default, the GitLab instance is configured to use the [Open VSX](https://open-vsx.org/)
extension registry. To enable the extension marketplace with this default configuration:

Prerequisites:

- You must be an administrator.

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > General**.
1. Expand **VS Code Extension Marketplace**.
1. Toggle on **Enable Extension Marketplace** to enable the extension marketplace across the GitLab instance.

## Customize extension registry

To connect the GitLab instance with a custom extension registry:

Prerequisites:

- You must be an administrator.

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > General**.
1. Expand **VS Code Extension Marketplace**.
1. Expand **Extension registry settings**.
1. Toggle off **Use Open VSX extension registry**.
1. Enter full URLs for a VS Code extension registry's **Service URL**, **Item URL**, and **Resource URL Template**.
1. Select **Save changes**.

{{< alert type="note" >}}

After enabling the extension marketplace, users must still
[opt in to use the extension marketplace](../../user/profile/preferences.md#integrate-with-the-extension-marketplace).

If you modify the extension registry URLs:

- Users who previously opted in must opt in again with the new registry.
- Users who have not opted in are not affected.
- Active Web IDE or Workspaces sessions continue to use their current configuration until refreshed.

{{< /alert >}}
