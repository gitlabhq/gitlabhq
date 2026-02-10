---
stage: Fulfillment
group: Utilization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Understand how GitLab Credits work and view your credit usage.
title: GitLab Credits and usage billing
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- Introduced in GitLab 18.7.

{{< /history >}}

GitLab Credits are the standardized consumption currency for usage-based billing.
Credits are used for [GitLab Duo Agent Platform](../user/duo_agent_platform/_index.md),
where each usage action consumes a number of credits.

[GitLab Duo Pro and Enterprise](subscription-add-ons.md#gitlab-duo-pro-and-enterprise) and their associated [GitLab Duo (Classic) features](../user/gitlab_duo/feature_summary.md) are not billed based on usage and do not consume GitLab Credits.

Credits are calculated based on the features and models you use, as listed in the credit multiplier tables.
You are billed for features that are [generally available](../policy/development_stages_support.md#generally-available).

GitLab provides three ways to obtain credits:

- Included credits
- Monthly Commitment Pool
- On-Demand credits

For a click-through demo, see [GitLab Credits](https://gitlab.navattic.com/credits-dashboard).
<!-- Demo published on 2026-01-28 -->

For information about credit pricing, see [GitLab pricing](https://about.gitlab.com/pricing/).

## Included credits

Included credits are allocated to all users on a Premium or Ultimate tier.
These credits are individual and cannot be shared between users.
Included credits reset at the beginning of each month.
Unused credits do not roll over to the next month.

For more information about included credits, see [GitLab Promotions Terms & Conditions](https://about.gitlab.com/pricing/terms/).

## Monthly Commitment Pool

Monthly Commitment Pool is a shared pool of credits available to all users in the subscription.
All users in your subscription can draw from this shared pool after they have consumed their included credits.

You can purchase the Monthly Commitment Pool as a recurring annual or multi-year term.
The number of credits purchased for the year is divided in 12.

For example, when you purchase a monthly commitment pool of 1,000 credits,
you will have 1,000 credits available each month for the contract term.

You can increase your commitment at any time through your GitLab account team.
The additional commitment applies for the remainder of your contract term.
You can decrease your commitment only at the time of renewal.

You can purchase a commitment of credits with built-in tiered discounting.
The commitment is billed up front at the start of the contract term.

Credits become available immediately after purchase, and reset on the first of every month.
Unused credits do not roll over to the next month.

> [!note]
> When purchasing a monthly commitment pool, you accept the usage billing terms, including On-Demand credit usage.

## On-Demand credits

On-Demand credits cover usage incurred after you have used all included credits
and the credits in the Monthly Committed Pool.
On-Demand credits are billed monthly.

On-Demand credits are consumed at the list price of $1 per credit used.

On-Demand credits can be used after you have accepted usage billing terms.
You can accept these terms when you purchase your monthly commitment,
or directly in the GitLab Credits dashboard.
By accepting usage billing terms, you agree to pay for all On-Demand charges already accrued
in the current monthly billing period, and any On-Demand charges incurred going forward.

If you haven’t accepted usage billing terms, you can’t use GitLab Duo Agent Platform and consume On-Demand credits.
You can regain access to GitLab Duo Agent Platform by either purchasing
a monthly commitment or accepting the usage billing terms.

For example, a subscription has a monthly commitment of 50 credits per month.
If 75 credits are used in that month, the first 50 credits are part of the monthly commitment pool,
and the additional 25 are billed as on-demand usage.

## Usage order

GitLab Credits are consumed in the following order:

1. Included credits are used by each user first.
1. Monthly Commitment Pool of credits are used after all included credits have been consumed.
1. On-Demand credits are used after all other available credits
   (included credits and Monthly Commitment Pool, if applicable) are depleted and usage billing terms are signed.

## Temporary evaluation credits

If you have not purchased the Monthly Commitment Pool or accepted the usage billing terms for On-Demand credits,
you can request a free temporary pool of credits to evaluate GitLab Duo Agent Platform features.

Credits are allocated based on the number of users you request for the evaluation,
and added to a shared pool for those users.
Credits are valid for 30 days, and cannot be used after they expire.

To request credits, [contact the Sales team](https://about.gitlab.com/sales/).

If you're on the Free tier and want to try credits, you can start an [Ultimate trial](free_trials.md).

## Buy GitLab Credits

You can buy GitLab Credits for your Monthly Commitment Pool in Customers Portal.

{{< tabs >}}

{{< tab title="Customers Portal" >}}

Prerequisites:

- You must be a billing account manager.

1. Sign in to [Customers Portal](https://customers.gitlab.com/).
1. On the relevant subscription card, select **GitLab Credits dashboard**.
1. Select **Purchase monthly commitment** or **Increase monthly commitment**.
1. Enter the number of credits you want to buy.
1. Select **Review order**. Verify that the number of credits, customer information, and payment method are correct.
1. Select **Confirm purchase**.

{{< /tab >}}

{{< tab title="GitLab.com" >}}

Prerequisites:

- You must have the Owner role for the group.

1. In the top bar, select **Search or go to** and find your top-level group.
1. Select **Settings** > **GitLab Credits**.
1. Select **Purchase monthly commitment** or **Increase monthly commitment**.
1. In the Customers Portal form, enter the number of credits you want to buy.
1. Select **Review order**. Verify that the number of credits, customer information, and payment method are correct.
1. Select **Confirm purchase**.

{{< /tab >}}

{{< tab title="GitLab Self-Managed" >}}

Prerequisites:

- You must be an administrator.
- Your instance must be able to synchronize your subscription data with GitLab.

1. In the upper-right corner, select **Admin**.
1. Select **GitLab Credits**.
1. Select **Purchase monthly commitment** or **Increase monthly commitment**.
1. In the Customers Portal form, enter the number of credits you want to buy.
1. Select **Review order**. Verify that the number of credits, customer information, and payment method are correct.
1. Select **Confirm purchase**.

{{< /tab >}}

{{< /tabs >}}

Your GitLab Credits are displayed in the subscription card in Customers Portal, and in the GitLab Credits dashboard.

## Credit multipliers

Credit usage is calculated based on the features and models they use.
Some features have multiple model options to choose from, while other features use only one model.

### Models

The following table lists the number of requests you can make with one GitLab Credit for different models.
Newer, more complex models have a higher multiplier and require more credits.

For subsidized models with basic integration:

| Model | Requests with one credit |
|-------|------------------------|
| `claude-3-haiku` | 8.0 |
| `codestral-2501` | 8.0 |
| `gemini-2.0-flash-lite` | 8.0 |
| `gemini-2.5-flash` | 8.0 |
| `gpt-5-mini` | 8.0 |

For premium models with optimized integration:

| Model | Requests with one credit |
|-------|------------------------|
| `claude-4.5-haiku` (default Agentic Chat model) | 6.7 |
| `gpt-5-codex` | 3.3|
| `gpt-5` | 3.3 |
| `gpt-5.2` | 2.5 |
| `claude-3.5-sonnet` | 2.0 |
| `claude-3.7-sonnet` | 2.0 |
| `claude-sonnet-4` <sup>1</sup> (default model) | 2.0 |
| `claude-sonnet-4.5` <sup>1</sup> | 2.0 |
| `claude-opus-4.5` | 1.2 |
| `claude-opus-4.6` <sup>1</sup> | 1.2 |
| `claude-sonnet-4` <sup>2</sup> | 1.1 |
| `claude-sonnet-4.5` <sup>2</sup> | 1.1 |
| `claude-opus-4.6` <sup>2</sup> | 0.7 |

**Footnotes**:

1. Prompts with up to 200,000 tokens.
1. Prompts with more than 200,000 tokens.

### Features

The following table lists the number of requests you can make with one GitLab Credit for features that use a fixed model.

| Feature | Requests with one credit |
|---------|---------------------------|
| [GitLab Duo Code Suggestions](../user/duo_agent_platform/code_suggestions/_index.md) | 50 |

[GitLab Duo Chat (Agentic)](../user/gitlab_duo_chat/agentic_chat.md) doesn't use a fixed model,
so credit cost varies based on the model selected for the request.
With the default model (`claude-4.5-haiku`) you can make 6.7 requests with one credit.

## GitLab Credits dashboard

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed

{{< /details >}}

{{< history >}}

- Introduced in GitLab 18.7.

{{< /history >}}

The GitLab Credits dashboard displays information about your usage of GitLab Credits.
Use the dashboard to monitor credit consumption, track trends, and identify usage patterns.

On the dashboard, used credits represent deductions from available credits.
For overages (On-Demand credits), used credits represent on-demand usage that will be paid later,
if you have agreed to the usage billing terms.

To help you manage credit consumption, GitLab emails the following information to
administrators and subscription owners:

- Monthly credit usage summaries
- Notifications when credit usage thresholds are at 50%, 80%, and 100%

You can access the dashboard in the Customers Portal and in GitLab.

> [!note]
> Usage data is not displayed in real time.
> Data is synchronized to the dashboards periodically, so usage data should appear within a few hours of actual consumption.
> This means your dashboard shows recent usage, but might not reflect actions taken in the last few hours.

### In Customers Portal

The GitLab Credits dashboard in the Customers Portal provides the most detailed view of your usage and costs.

The dashboard displays summary cards of key metrics:

- Current month usage: Total GitLab Credits used in the current month (if you have a monthly commitment)
- Included credits: Total credits included with your subscription (if you have a monthly commitment)
- Committed credits: Credits from your Monthly Committed Pool (if applicable)
- Monthly waivers: Remaining credits from waivers (if applicable)
- On-Demand usage: Credits consumed beyond your included and committed amounts.
  If you have enough waiver credits to offset all On-Demand credits, the GitLab Credits Dashboard hides
  the **On-Demand** card and displays the **Monthly Waiver** card instead.

### In GitLab

The GitLab Credits dashboard in GitLab provides operational visibility into the usage of credits in your organization.
Use the dashboard to understand which users, groups, or projects are driving usage, and make informed decisions about resource allocation.

The dashboard displays the following information:

- Organization usage: Total credit usage across your GitLab instance or group
- Detailed credit usage by user: Number of credits used by each user

### View the GitLab Credits dashboard

{{< tabs >}}

{{< tab title="Customers Portal" >}}

Prerequisites:

- To view detailed usage information, you must be a billing account manager.

1. Sign in to [Customers Portal](https://customers.gitlab.com/).
1. On the subscription card, select **GitLab Credits dashboard**.

{{< /tab >}}

{{< tab title="GitLab.com" >}}

Prerequisites:

- You must have the Owner role for the group.

1. In the top bar, select **Search or go to** and find your top-level group.
1. Select **Settings** > **GitLab Credits**.

{{< /tab >}}

{{< tab title="GitLab Self-Managed" >}}

Prerequisites:

- You must be an administrator.
- Your instance must be able to synchronize your subscription data with GitLab.

1. In the upper-right corner, select **Admin**.
1. Select **GitLab Credits**.

{{< /tab >}}

{{< /tabs >}}

By default, individual user data is not displayed in the GitLab Credits dashboard.
To display it, you must enable this setting for your [group](../user/group/manage.md#display-gitlab-credits-user-data) or [instance](../administration/settings/visibility_and_access_controls.md#display-gitlab-credits-user-data).
