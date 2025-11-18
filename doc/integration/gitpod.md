---
stage: Create
group: Remote Development
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Use Ona to build and configure prebuilt development environments for your GitLab project.
title: Ona
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed

{{< /details >}}

With [Ona](https://ona.com/) (formerly Gitpod), you can describe your development environment as code to get fully
set up, compiled, and tested development environments for any GitLab project. The development
environments are not only automated but also prebuilt which means that Ona continuously builds
your Git branches like a CI/CD server.

This means you don't have to wait for dependencies to download and builds to start
coding immediately. With Ona you can start coding instantly on any project, branch, and merge
request from your browser.

To use the GitLab Ona integration, you must enable it for your GitLab instance and in your preferences. Users of:

- GitLab.com can use it immediately after it's [enabled in their user preferences](#enable-ona-in-your-user-preferences).
- GitLab Self-Managed instances can use it after:
  1. It's [enabled and configured by a GitLab administrator](#configure-a-gitlab-self-managed-instance).
  1. It's [enabled in their user settings](#enable-ona-in-your-user-preferences).

For more information about Ona, see the Ona [features](https://ona.com/) and
[documentation](https://ona.com/docs).

## Enable Ona in your user preferences

With the Ona integration enabled for your GitLab instance, to enable it for yourself:

1. On the left sidebar, select your avatar. If you've [turned on the new navigation](../user/interface_redesign.md#turn-new-navigation-on-or-off), this button is in the upper-right corner.
1. Select **Preferences**.
1. Under **Preferences**, locate the **Integrations** section.
1. Select the **Enable Ona integration** checkbox and select **Save changes**.

## Configure a GitLab Self-Managed instance

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

For GitLab Self-Managed, a GitLab administrator must:

1. Enable the Ona integration in GitLab:
   1. On the left sidebar, at the bottom, select **Admin**. If you've [turned on the new navigation](../user/interface_redesign.md#turn-new-navigation-on-or-off), in the upper-right corner, select **Admin**.
   1. On the left sidebar, select **Settings** > **General**.
   1. Expand the **Ona** configuration section.
   1. Select the **Enable Ona integration** checkbox.
   1. Enter the Ona instance URL (for example, `https://app.ona.com`).
   1. Select **Save changes**.
1. Register the instance in Ona. For more information, see the [Ona documentation](https://ona.com/docs/ona/source-control/gitlab).

GitLab users can then [enable the Ona integration for themselves](#enable-ona-in-your-user-preferences).

## Launch Ona in GitLab

After you [enable Ona](#enable-ona-in-your-user-preferences),
you can launch it from GitLab in one of these ways:

- From a project repository:
  1. On the left sidebar, select **Search or go to** and find your project. If you've [turned on the new navigation](../user/interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
  1. In the upper right, select **Code** > **Ona**.

- From a merge request:
  1. Go to your merge request.
  1. In the upper-right corner, select **Code** > **Open in Ona**.

Ona builds your development environment for your branch.
