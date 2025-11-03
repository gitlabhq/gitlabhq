---
stage: Create
group: Remote Development
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Configure VS Code Extension Marketplace for features on the GitLab Self-Managed instance.
title: Configure VS Code Extension Marketplace
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

The VS Code Extension Marketplace provides access to extensions that enhance the functionality of the
Web IDE and Workspaces. Administrators can configure access to the marketplace for the entire instance.

{{< alert type="note" >}}

To access the VS Code Extension Marketplace, your browser must be able to access the `.cdn.web-ide.gitlab-static.net` assets host.
This security requirement ensures that third-party extensions run in isolation and cannot access your account.

{{< /alert >}}

## Access VS Code Extension Marketplace settings

Prerequisites:

- You must be an administrator.

To access the VS Code Extension Marketplace settings:

1. On the left sidebar, at the bottom, select **Admin**. If you've [turned on the new navigation](../../user/interface_redesign.md#turn-new-navigation-on-or-off), in the upper-right corner, select your avatar and then select **Admin**.
1. Select **Settings** > **General**.
1. Expand **VS Code Extension Marketplace**.

## Enable the extension registry

By default, the GitLab instance is configured to use the [Open VSX](https://open-vsx.org/)
extension registry. To enable the extension marketplace with this default configuration:

Prerequisites:

- You must be an administrator.

1. On the left sidebar, at the bottom, select **Admin**. If you've [turned on the new navigation](../../user/interface_redesign.md#turn-new-navigation-on-or-off), in the upper-right corner, select your avatar and then select **Admin**.
1. Select **Settings** > **General**.
1. Expand **VS Code Extension Marketplace**.
1. Toggle on **Enable Extension Marketplace** to enable the extension marketplace across the GitLab instance.

## Modify the extension registry

Prerequisites:

- You must be an administrator.

To modify the extension registry:

1. On the left sidebar, at the bottom, select **Admin**. If you've [turned on the new navigation](../../user/interface_redesign.md#turn-new-navigation-on-or-off), in the upper-right corner, select your avatar and then select **Admin**.
1. Select **Settings** > **General**.
1. Expand **VS Code Extension Marketplace**.
1. Expand **Extension registry settings**.
1. Toggle off **Use Open VSX extension registry**.
1. Enter full URLs for a VS Code extension registry's **Service URL**, **Item URL**, and **Resource URL Template**.
1. Select **Save changes**.

After you modify the extension registry:

- Active Web IDE or Workspace sessions continue to use their previous registry until refreshed.
- All users must [integrate their account with the new registry](../../user/profile/preferences.md#integrate-with-the-extension-marketplace) before they can use extensions.
