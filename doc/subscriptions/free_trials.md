---
stage: Growth
group: Acquisition
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Start an Ultimate trial on GitLab.com or GitLab Self-Managed.
title: Ultimate trials
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed

{{< /details >}}

You can get a trial license for the GitLab Ultimate tier.

During the trial period, you have access to nearly all Ultimate features.

A trial license for Ultimate is valid for:

- 30 days if you're on the Free tier.
- 60 days if you're on the Premium tier.

The trial starts when you receive the confirmation email including the activation code, not when you activate it.

When the trial period is over, you lose access to paid features. To maintain access, you can [buy a subscription](manage_subscription.md#buy-a-subscription).

## GitLab Duo Agent Platform trials

Prerequisites:

- For GitLab Self-Managed, you must have GitLab 18.9 or later.
- For GitLab.com, your trial must start after February 10, 2026.

If you're on the Free tier and you start an Ultimate trial, your trial includes 24 [GitLab credits](gitlab_credits.md#included-credits) per user.
You can use credits to test GitLab Duo Agent Platform features.

Credits are valid for the duration of the trial (30 days). Unused credits do not carry over if you buy a subscription, or when your trial ends.
If you use all included credits before your trial ends, you cannot get more credits.

If you already started or completed a trial that did not include credits, you can start a new trial:

- If your trial has expired, you can start a new trial immediately.
- If your trial is still active, you must complete your current trial period before starting a new one.

If you're on the Premium tier, your trial does not provide additional credits over and above your existing included credits per user.
You can request additional [temporary evaluation credits](gitlab_credits.md#temporary-evaluation-credits) to try GitLab Duo Agent Platform features.

## Start a trial on GitLab.com

You can start a trial even if you have not signed up for a GitLab account yet.

### If you don't have an account

If you don't have a GitLab account, to start a free trial:

1. Go to [https://gitlab.com/-/trial_registrations/new](https://gitlab.com/-/trial_registrations/new).
1. Fill in the form details, and select **Continue**.
1. Complete the remaining steps and select **Create project**. You are taken to your new project and signed in as the new user you created.
1. In the left sidebar, at the bottom, a widget displays your trial type and the remaining days in your trial.

### If you already have an account

If you already have a GitLab account, you can start a trial directly from your group settings.

Prerequisites:

- You must have the Owner role for the top-level group the trial should be applied to. Indirect ownership through group membership is not sufficient.
- The top-level group must not have trialed previously with GitLab Credits.

To start a trial:

1. On the top bar, select **Search or go to** and find your group.
1. Select **Settings** > **Billing**.
1. Select **Start free trial**.
1. Complete the fields.
1. Select **Continue**.
1. Select the group the trial should be applied to.
1. Select **Activate my trial**.

Your trial starts immediately. In the left sidebar, at the bottom, a widget displays your trial type and the remaining days in your trial.

## Start a trial on GitLab Self-Managed

To start a trial for GitLab Self-Managed, complete a form to receive a trial license by email.

Prerequisites:

- You must have a GitLab Self-Managed instance [installed](../install/_index.md) and configured.
- Your instance must be able to [synchronize your subscription data](manage_subscription.md#subscription-data-synchronization) with GitLab.
- You must be an administrator.

To start a trial:

1. Go to the [GitLab Ultimate](https://about.gitlab.com/free-trial/?hosted=self-managed) trial page.
1. Complete the fields.
1. Select **Get Started**.
1. Check your email for the trial activation code.
   The email with the activation code is sent shortly after the trial request submission, to the email address provided in the trial request form.
   The activation code is valid for only one use.
1. Sign in to GitLab as an administrator.
1. In the upper-right corner, select **Admin**.
1. Select **Subscription**.
1. Paste the activation code in **Activation code**.
1. Read and accept the terms of service.
1. Select **Activate**.

The subscription is activated.

## View remaining trial period days

You can keep track of your remaining trial period time to help you plan for a subscription upgrade.

1. On the top bar, select **Search or go to** and find your group.
1. In the left sidebar, at the bottom, a widget displays your trial type and the remaining days in your trial.
1. On GitLab Self-Managed, to access information about features available when you upgrade, select **Learn more**.
