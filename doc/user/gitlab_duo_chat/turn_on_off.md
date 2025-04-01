---
stage: AI-powered
group: Duo Chat
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Control GitLab Duo Chat availability
---

GitLab Duo Chat can be turned on and off, and availability changed.

## For GitLab.com

In GitLab 16.11 and later, GitLab Duo Chat is:

- Generally available.
- Available to any user with an assigned GitLab Duo seat.

If you [turn on or turn off GitLab Duo](../gitlab_duo/turn_on_off.md), you turn on or turn off Duo Chat as well.

## For GitLab Self-Managed

To use GitLab Duo Chat on a GitLab Self-Managed instance, do one of the following:

- Use the GitLab AI vendor models and the cloud-based AI gateway that’s hosted by GitLab (default option).
- [Use GitLab Duo Self-Hosted to self-host the AI gateway, with a supported self-hosted LLM](../../administration/gitlab_duo_self_hosted/_index.md#set-up-a-gitlab-duo-self-hosted-infrastructure).

Prerequisites:

- GitLab Duo requires GitLab 17.2 and later for the best user experience and results. Earlier versions may continue to work, however the experience may be degraded.
- For subscriptions:
  - If you are using GitLab AI vendor models and the cloud-based AI gateway, you
  must have a Premium or Ultimate subscription that is [synchronized with GitLab](https://about.gitlab.com/pricing/licensing-faq/cloud-licensing/). To make sure GitLab Duo Chat works immediately, administrators can
  [manually synchronize your subscription](#manually-synchronize-your-subscription).
  - If you are using GitLab Duo Self-Hosted, you must have an Ultimate subscription with the GitLab Duo Enterprise add-on.
- You must have [enabled network connectivity](../gitlab_duo/setup.md).
- [Silent Mode](../../administration/silent_mode/_index.md) must not be turned on.
- All of the users in your instance must have the latest version of their IDE extension.

Then, depending on the version of GitLab you have, you can enable GitLab Duo Chat.

### In GitLab 16.11 and later

In GitLab 16.11 and later, GitLab Duo Chat is:

- Generally available.
- Available to any user with an assigned GitLab Duo seat.

### In earlier GitLab versions

In GitLab 16.8, 16.9, and 16.10, GitLab Duo Chat is available in beta. To enable GitLab Duo Chat for GitLab Self-Managed, an administrator must enable experiment and beta features:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > General**.
1. Expand **AI-powered features** and select **Enable Experiment and Beta AI-powered features**.
1. Select **Save changes**.
1. To make sure GitLab Duo Chat works immediately, you must
   [manually synchronize your subscription](#manually-synchronize-your-subscription).

{{< alert type="note" >}}

Usage of GitLab Duo Chat beta is governed by the [GitLab Testing Agreement](https://handbook.gitlab.com/handbook/legal/testing-agreement/).
Learn about [data usage when using GitLab Duo Chat](../gitlab_duo/data_usage.md).

{{< /alert >}}

### Manually synchronize your subscription

You can [manually synchronize your subscription](../../subscriptions/self_managed/_index.md#manually-synchronize-subscription-data) if either:

- You have just purchased a subscription for the Premium or Ultimate tier, or have recently assigned seats for GitLab Duo Pro, and you have upgraded to GitLab 16.8.
- You already have a subscription for the Premium or Ultimate tier, or you have recently assigned seats for GitLab Duo Pro, and you have upgraded to GitLab 16.8.

Without the manual synchronization, it might take up to 24 hours to activate GitLab Duo Chat on your instance.

## For GitLab Dedicated

In GitLab 16.11 and later, on GitLab Dedicated, GitLab Duo Chat is generally available and
automatically enabled for those with GitLab Duo Pro or Enterprise.

In GitLab 16.8, 16.9, and 16.10, on GitLab Dedicated, GitLab Duo Chat is available in beta.

## Disable GitLab Duo Chat

To limit the data that GitLab Duo Chat has access to, follow the instructions for
[disabling GitLab Duo features](../gitlab_duo/turn_on_off.md#turn-off-gitlab-duo-features).

## Disable Chat in VS Code

To disable GitLab Duo Chat in VS Code:

1. Go to **Settings > Extensions > GitLab Workflow**.
1. Clear the **Enable GitLab Duo Chat assistant** checkbox.
