---
stage: Fulfillment
group: Utilization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Understand how GitLab Credits work and view your credit usage.
title: GitLab Credits and usage billing
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- Introduced in GitLab 18.7.
- GitLab Duo Agent Platform and GitLab Credits supported on GitLab 18.8 and later.
- Introduced for community subscriptions in GitLab 18.11.
- Credit usage order changed in GitLab 19.4.

{{< /history >}}

GitLab Credits are the standardized consumption currency for usage-based billing.
Credits are used for [GitLab Duo Agent Platform](../user/duo_agent_platform/_index.md) and some non-agentic [features](#features),
where each usage action consumes a number of credits.

[GitLab Duo Pro and Enterprise](subscription-add-ons.md#gitlab-duo-pro-and-enterprise) and their associated [GitLab Duo features](../user/gitlab_duo/feature_summary.md) are not billed based on usage and do not consume GitLab Credits.

Credits are calculated based on the features and models you use, as listed in the credit multiplier tables.
You are billed for features that are [generally available](../policy/development_stages_support.md#generally-available).
Some pre-release features also incur usage charges. If charges apply, the feature's documentation page notes this.

Billing occurs at the root namespace or top-level group level, not at the project level.
Credit usage is attributed to the subject who performs the action, regardless of which project they are using the features in.
A subject is either a human user or a non-human subject (for example, a service account or a bot running an automated flow).

All usage in a root namespace or top-level group is consolidated for billing purposes.

GitLab provides three ways to obtain credits:

- Included credits
- Monthly Commitment Pool
- On-Demand credits

For a click-through demo, see [GitLab Credits](https://gitlab.navattic.com/credits-dashboard).
<!-- Demo published on 2026-01-28 -->

For information about credit pricing, see [GitLab pricing](https://about.gitlab.com/pricing/).

## For the Free tier

{{< details >}}

- Tier: Free
- Offering: GitLab.com, GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/work_items/20165) in GitLab 18.10 for GitLab.com.
- Enabled on GitLab Self-Managed in GitLab 19.0.

{{< /history >}}

Users on the Free tier can purchase a Monthly Commitment Pool of GitLab Credits for their instance or group namespace. This provides access to a set of [GitLab Duo Agent Platform features](../user/duo_agent_platform/_index.md), without needing a Premium or Ultimate subscription.

On-demand usage for Free namespaces is capped at $25,000 for each calendar month. Upon reaching this limit, on-demand usage is automatically turned off and resets at the beginning of the following month.

## Included credits

Included credits are allocated to all users on a Premium or Ultimate tier.
These credits are individual and cannot be shared between users.
Included credits reset at the beginning of each month.
Unused credits do not roll over to the next month.

[Community program subscriptions](community_programs.md) do not receive included credits.

Non-human subjects do not receive included credits.
Their consumption is billed at the namespace level from the Monthly Commitment Pool and On-Demand credits,
in the same usage order as for human users.

For more information about included credits, see [GitLab Promotions Terms & Conditions](https://about.gitlab.com/pricing/terms/).

## Temporary evaluation credits

If you have not purchased the Monthly Commitment Pool or accepted the usage billing terms for On-Demand credits,
you can request a free temporary pool of credits to evaluate credit-based features.

Credits are allocated based on the number of users you request for the evaluation,
and added to a shared pool for those users.
Credits are valid for 30 days, and cannot be used after they expire.

To request credits, [contact the Sales team](https://about.gitlab.com/sales/).

If you're on the Free tier and want to try credits, you can start an [Ultimate trial](free_trials.md).

## Monthly Commitment Pool

Monthly Commitment Pool is a shared pool of credits available to all users in the subscription.
All users in your subscription can draw from this shared pool after they have consumed their included credits.

You can't reserve the pool for a subset of users or isolate consumption to specific users, groups, or projects.
To limit how much individual users consume, use [usage caps](gitlab_credits_dashboard.md#usage-caps).

When you purchase a Monthly Commitment Pool, you accept the usage billing terms.

You can purchase the Monthly Commitment Pool as a recurring annual or multi-year term.
The number of credits purchased for the year is divided by 12.

For example, when you purchase a monthly commitment pool of 1,000 credits,
you will have 1,000 credits available each month for the contract term.

You can increase your commitment at any time through your GitLab account team.
The additional commitment applies for the remainder of your contract term.
You can decrease your commitment only at the time of renewal.

You can purchase a commitment of credits with built-in tiered discounting.
The commitment is billed up front at the start of the contract term.

Credits become available immediately after purchase, and reset on the first of every month.
Unused credits do not roll over to the next month.

## On-Demand credits

On-Demand credits cover usage incurred after you have used all included credits
and the credits in the Monthly Committed Pool.
On-Demand credits are billed monthly, at the list price of $1 per credit used.

To use On-Demand credits, you must accept the usage billing terms.

For example, a subscription has a monthly commitment of 50 credits per month.
If 75 credits are used in that month, the first 50 credits are part of the monthly commitment pool,
and the additional 25 are billed as on-demand usage.

## Usage order

GitLab Credits are consumed in the following order:

1. Included credits are used by each user first.
1. Temporary evaluation credits are used after a user's included credits are consumed.
1. Monthly Commitment Pool of credits is used after all included credits have been consumed.
1. On-Demand credits are used after all other available credits
   (included credits and Monthly Commitment Pool, if applicable) are depleted and usage billing terms are signed.

Other credit types, such as One-Time Charge credits, might apply to your subscription.
For details, contact your account team.

## Usage billing terms

When you buy a Monthly Commitment Pool, you accept the usage billing terms, including On-Demand credit usage.
By accepting usage billing terms, you agree to pay for all On-Demand charges already accrued
in the current monthly billing period, and any On-Demand charges incurred going forward.

You can accept the usage billing terms when you purchase a Monthly Commitment Pool, or directly in the GitLab Credits dashboard in Customers Portal.

After you accept the terms, On-Demand billing stays active for the rest of your subscription and subsequent self-serve renewals,
and you cannot opt out.

If you don't accept the usage billing terms, you can keep using credit-based features until you consume your
included credits and any temporary evaluation credits.

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

On the Premium and Ultimate tier:

1. In the top bar, select **Search or go to** and find your top-level group.
1. Select **Settings** > **GitLab Credits**.
1. Select **Purchase monthly commitment** or **Increase monthly commitment**.
1. In the Customers Portal form, enter the number of credits you want to buy.
1. Select **Review order**. Verify that the number of credits, customer information, and payment method are correct.
1. Select **Confirm purchase**.

On the Free tier:

1. In the top bar, select **Search or go to** and find your top-level group.
1. Select **Settings** > **Billing**.
1. If you:
   - Are not on a trial: On the GitLab Credits card, select **Purchase credits** or **Increase credits**.
   - Are on an active trial: On the GitLab Credits card, select **Purchase monthly commitment** or **Increase credits**.
1. In the Customers Portal form, enter the number of credits you want to buy.
1. Select **Review order**. Verify that the number of credits, customer information, and payment method are correct.
1. Select **Confirm purchase**.

{{< /tab >}}

{{< tab title="GitLab Self-Managed" >}}

Prerequisites:

- You must be an administrator.
- Your instance must be able to synchronize your subscription data with GitLab.

On the Premium and Ultimate tier:

1. In the upper-right corner, select **Admin**.
1. In the left sidebar, select **GitLab Credits**.
1. Select **Purchase monthly commitment** or **Increase monthly commitment**.
1. In the Customers Portal form, enter the number of credits you want to buy.
1. Select **Review order**. Verify that the number of credits, customer information, and payment method are correct.
1. Select **Confirm purchase**.

On the Free tier:

1. In the upper-right corner, select **Admin**.
1. In the left sidebar, select **Subscription**.
1. On the GitLab Credits card, select **Purchase credits**.
1. If you do not have a Customers Portal account, first complete the steps to create an account. Then use your credentials to sign in.
1. In the Customers Portal form, enter the number of credits you want to buy.
1. Select **Review order**. Verify that the number of credits, customer information, and payment method are correct.
1. Select **Confirm purchase**.

{{< /tab >}}

{{< /tabs >}}

Your GitLab Credits are displayed in the Customers Portal in the subscription card and the GitLab Credits dashboard.

## Credit multipliers

Credit usage is calculated based on the features and models they use.
Some features have multiple model options to choose from, while other features use only one model.

A request represents a single (billable) action initiated by a user (for example, sending a chat message or requesting code generation).
This represents one interaction from the user's perspective.

A model call represents the underlying API calls made to LLMs to fulfill a user request.
A single user request might trigger multiple model calls. For example, one call to understand context and another call to generate a response.

### Models

The following table lists the number of LLM calls you can make with one GitLab Credit for different [models](../user/duo_agent_platform/model_selection.md).
Newer, more complex models have a higher multiplier and require more credits.

You are charged for model usage based on the following billing methods:

- Variable pricing for GitLab-managed models: A request is equivalent to a single LLM call. One flow makes one or many calls. The credit cost depends on the model used.
- Variable pricing for self-hosted models: A request is equivalent to a single LLM call. One flow makes one or many calls. You can make eight requests with one credit for any [supported](../administration/gitlab_duo_self_hosted/supported_models_and_hardware_requirements.md#supported-models) or [compatible](../administration/gitlab_duo_self_hosted/supported_models_and_hardware_requirements.md#compatible-models) self-hosted model.
- Flat pricing for GitLab Duo features: Each end-to-end execution consumes a pre-set amount of credits, regardless of how many LLM calls (GitLab-managed and self-hosted models) are made during execution. Features that run on a self-hosted model receive a 20% discount on the credits consumed for an execution.
- Credit deduction for a failed execution depends on the offering:
  - On GitLab.com with GitLab-managed models, a flow that fails before it completes deducts no credits, even if some LLM calls were already made.
  - On GitLab Self-Managed with self-hosted models, for features that do not use a flat price, billing is based on individual LLM calls, not flow completion. Each call is metered when it starts, so calls made before a flow fails are still billed. This means a flow that fails partway through may still consume credits for the calls that were already initiated. For flat-priced features, the full flat price is charged even if the flow fails, regardless of how many LLM calls were actually made.

For subsidized models with basic integration:

| Model | Calls with one credit |
|-------|------------------------|
| `claude-3-haiku` | 8.0 |
| `codestral-2501` | 8.0 |
| `gemini-2.5-flash` | 8.0 |
| `gpt-5-mini` | 8.0 |
| `gpt-5-4-nano` | 8.0 |

For premium models with optimized integration:

| Model | Calls with one credit |
|-------|------------------------|
| `gpt-5.6-luna` | 8.0 |
| `claude-4.5-haiku` | 6.7 |
| `gemini-3.6-flash` <sup>1</sup> | 6.7 |
| `gemini-3.7-flash` <sup>1</sup> | 6.7 |
| `gemini-3.8-flash` <sup>1</sup> | 6.7 |
| `gpt-5-4-mini` | 6.7 |
| `gemini-3.5-flash` | 3.3 |
| `gpt-5` | 3.3 |
| `gpt-5-codex` | 3.3 |
| `claude-sonnet-5` | 3.2 |
| `gpt-5.2` | 2.5 |
| `gpt-5.2-codex` | 2.5 |
| `gpt-5.3-codex` | 2.5 |
| `gpt-5.6-terra` <sup>3</sup> | 2.5 |
| `claude-3.5-sonnet` | 2.0 |
| `claude-3.7-sonnet` | 2.0 |
| `claude-sonnet-4.5` | 2.0 |
| `claude-sonnet-4.6` | 2.0 |
| `gpt-5.4` <sup>3</sup> | 2.0 |
| `gpt-5.6-terra` <sup>4</sup> | 1.43 |
| `gpt-5.6-sol` <sup>2</sup> <sup>3</sup> | 1.33 |
| `claude-opus-4.5` | 1.2 |
| `gpt-5.4` <sup>4</sup> | 1.11 |
| `claude-opus-4.6` | 1.1 |
| `claude-opus-4.7` | 1.1 |
| `claude-opus-4.8` | 1.1 |
| `claude-opus-5` | 1.1 |
| `gpt-5.5` <sup>3</sup> | 1.0 |
| `gpt-5.6-sol` <sup>4</sup> | 0.76 |
| `claude-fable-5` | 0.6 |
| `claude-fable-5.1` | 0.6 |
| `gpt-5.5` <sup>4</sup> | 0.57 |

**Footnotes**:

1. Promotional pricing through December 31, 2026.
   Afterwards, the rate changes to approximately 3.3 calls per credit.
1. Promotional pricing for GPT-5.6 Sol through November 21, 2026.
   Afterwards, the rates change to approximately 1.0 calls per credit
   for the short context window and 0.57 for the long context window.
1. Short context window of up to 272,000 tokens.
1. Long context window of more than 272,000 tokens.

### Features

{{< history >}}

- Self-hosted model discount introduced in GitLab 19.1 [with a feature flag](../administration/feature_flags/_index.md) named `self_hosted_flat_pricing_discount`.

{{< /history >}}

> [!flag]
> The availability of the self-hosted model discount is controlled by a feature flag.
> For more information, see the history.

The following table lists the number of executions you can make with one GitLab Credit for different features.
This pricing applies to all models (including self-hosted models) available for the feature.

A feature that runs on a [self-hosted model](../administration/gitlab_duo_self_hosted/_index.md) receives a 20% discount.

| Feature | Executions with one credit (GitLab-managed model) | Executions with one credit (self-hosted model) |
|---------|----------------------------|------------------------------------------------|
| [GitLab Duo Code Suggestions](../user/duo_agent_platform/code_suggestions/_index.md) | 50 | 62.5 |
| Code Review Flow | 4 | 5 |
| SAST False Positive Detection Flow | 1 | 1.25 |
| SAST Vulnerability Resolution Flow | 0.25 | 0.3125 |

For GitLab Duo Agentic Chat, one sent message counts as one or more billable requests,
because one or more LLM calls are made to answer the question.
One conversation window can include multiple messages, and so multiple billable requests.
The pricing depends on the selected model.

The following features also consume credits, but with a different consumption model:

- [GitLab Secrets Manager](../ci/secrets/secrets_manager/secrets_manager_billing.md)
- [Hosted runners for GitLab Dedicated](../administration/dedicated/hosted_runners.md#usage-cap-exemptions)
