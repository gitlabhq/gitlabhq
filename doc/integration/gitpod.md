---
stage: Create
group: Remote Development
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments"
description: "Use Gitpod to build and configure prebuilt development environments for your GitLab project."
title: Gitpod
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed

With [Gitpod](https://www.gitpod.io/), you can describe your development environment as code to get fully
set up, compiled, and tested development environments for any GitLab project. The development
environments are not only automated but also prebuilt which means that Gitpod continuously builds
your Git branches like a CI/CD server.

This means you don't have to wait for dependencies to download and builds to start
coding immediately. With Gitpod you can start coding instantly on any project, branch, and merge
request from your browser.

To use the GitLab Gitpod integration, you must enable it for your GitLab instance and in your preferences. Users of:

- GitLab.com can use it immediately after it's [enabled in their user preferences](#enable-gitpod-in-your-user-preferences).
- GitLab Self-Managed instances can use it after:
  1. It's [enabled and configured by a GitLab administrator](#configure-a-gitlab-self-managed-instance).
  1. It's [enabled in their user settings](#enable-gitpod-in-your-user-preferences).

For more information about Gitpod, see the Gitpod [features](https://www.gitpod.io/) and
[documentation](https://www.gitpod.io/docs).

## Enable Gitpod in your user preferences

With the Gitpod integration enabled for your GitLab instance, to enable it for yourself:

1. On the left sidebar, select your avatar.
1. Select **Preferences**.
1. Under **Preferences**, locate the **Integrations** section.
1. Select the **Enable Gitpod integration** checkbox and select **Save changes**.

## Configure a GitLab Self-Managed instance

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed, GitLab Dedicated

For GitLab Self-Managed, a GitLab administrator must:

1. Enable the Gitpod integration in GitLab:
   1. On the left sidebar, at the bottom, select **Admin**.
   1. On the left sidebar, select **Settings > General**.
   1. Expand the **Gitpod** configuration section.
   1. Select the **Enable Gitpod integration** checkbox.
   1. Enter the Gitpod instance URL (for example, `https://gitpod.example.com` or `https://gitpod.io`).
   1. Select **Save changes**.
1. Register the instance in Gitpod. For more information, see the [Gitpod documentation](https://www.gitpod.io/docs/configure/authentication/gitlab#registering-a-self-hosted-gitlab-installation).

GitLab users can then [enable the Gitpod integration for themselves](#enable-gitpod-in-your-user-preferences).

## Launch Gitpod in GitLab

After you [enable Gitpod](#enable-gitpod-in-your-user-preferences),
you can launch it from GitLab in one of these ways:

- **From a project repository:**
  1. On the left sidebar, select **Search or go to** and find your project.
  1. In the upper right, select **Edit > Gitpod**.

- **From a merge request:**
  1. Go to your merge request.
  1. In the upper-right corner, select **Code > Open in Gitpod**.

Gitpod builds your development environment for your branch.
