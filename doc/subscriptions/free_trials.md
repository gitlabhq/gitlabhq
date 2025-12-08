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
On GitLab.com, your trial includes a GitLab Duo Enterprise trial to test [GitLab Duo Enterprise features](../user/gitlab_duo/feature_summary.md).

A trial license for Ultimate and GitLab Duo Enterprise is valid for:

- 30 days if you're on the Free tier.
- 60 days if you're on the Premium tier.

When the trial period is over, you lose access to paid features. To maintain access, you can [buy a subscription](manage_subscription.md#buy-a-subscription).

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
- The top-level group must not have trialed previously.

To start a trial:

1. In the left sidebar, select **Search or go to** and find your group. If you've [turned on the new navigation](../user/interface_redesign.md), this field is on the top bar.
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

To start a trial on GitLab Self-Managed:

1. Go to [https://about.gitlab.com/free-trial/?hosted=self-managed](https://about.gitlab.com/free-trial/?hosted=self-managed).
1. Complete the fields.
1. Select **Get Started**.

### Add your trial license to your instance

To activate your trial, you must manually apply the license file you received by email to your GitLab instance.

1. Sign in to GitLab as an administrator.
1. In the left sidebar, at the bottom, select **Admin**. If you've [turned on the new navigation](../user/interface_redesign.md), this button is in the upper-right corner.
1. Select **Settings** > **General**.
1. In the **Add License** area, add a license by either uploading the file or entering the key.
1. Select the **Terms of Service** checkbox.
1. Select **Add license**.

The trial automatically synchronizes to your instance in 24 hours.

## View remaining trial period days

You can keep track of your remaining trial period time to help you plan for a subscription upgrade.

1. In the left sidebar, select **Search or go to** and find your group. If you've [turned on the new navigation](../user/interface_redesign.md), this field is on the top bar.
1. In the left sidebar, at the bottom, a widget displays your trial type and the remaining days in your trial.
1. On GitLab Self-Managed, to access information about features available when you upgrade, select **Learn more**.
