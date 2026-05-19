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

{{< /history >}}

GitLab Credits are the standardized consumption currency for usage-based billing.
Credits are used for [GitLab Duo Agent Platform](../user/duo_agent_platform/_index.md),
where each usage action consumes a number of credits.

[GitLab Duo Pro and Enterprise](subscription-add-ons.md#gitlab-duo-pro-and-enterprise) and their associated [GitLab Duo features](../user/gitlab_duo/feature_summary.md) are not billed based on usage and do not consume GitLab Credits.

Credits are calculated based on the features and models you use, as listed in the credit multiplier tables.
You are billed for features that are [generally available](../policy/development_stages_support.md#generally-available).

Billing occurs at the root namespace or top-level group level, not at the project level.
Credit usage is attributed to the subject who performs the action, regardless of which project they are using the features in.
A subject is either a human user or a non-human subject (for example, a service account or a bot running an automated flow).
For more information, see [Non-human subject usage](#non-human-subject-usage).
All usage in a root namespace or top-level group is consolidated for billing purposes.

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

[Community program subscriptions](community_programs.md) do not receive included credits.

Non-human subjects, such as service accounts and bots, do not receive included credits.
Their consumption is billed at the namespace level from the Monthly Commitment Pool and On-Demand credits.
For more information, see [Non-human subject usage](#non-human-subject-usage).

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
> After you accept the terms, On-Demand billing stays active for the rest of your subscription and subsequent self-serve renewals, and you cannot opt out.

## On-Demand credits

On-Demand credits cover usage incurred after you have used all included credits
and the credits in the Monthly Committed Pool.
On-Demand credits are billed monthly.

On-Demand credits are consumed at the list price of $1 per credit used.

On-Demand credits can be used after you have accepted usage billing terms.
You can accept these terms when you purchase your monthly commitment,
or directly in the GitLab Credits dashboard in the Customers Portal.
By accepting usage billing terms, you agree to pay for all On-Demand charges already accrued
in the current monthly billing period, and any On-Demand charges incurred going forward.

If you haven't accepted usage billing terms, you can't use GitLab Duo Agent Platform and consume On-Demand credits.
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
- Flat pricing for GitLab Duo features: Each successful end-to-end execution consumes a pre-set amount of credits, regardless of how many LLM calls (GitLab-managed and self-hosted models) are made during execution.

Only completed calls or executions are billed.
If a call or execution fails, no credits are deducted.

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
| `claude-4.5-haiku` | 6.7 |
| `gpt-5-4-mini` | 6.7 |
| `gpt-5-codex` | 3.3|
| `gpt-5` | 3.3 |
| `gpt-5.2` | 2.5 |
| `gpt-5.2-codex` | 2.5 |
| `gpt-5.3-codex` | 2.5 |
| `claude-3.5-sonnet` | 2.0 |
| `claude-3.7-sonnet` | 2.0 |
| `claude-sonnet-4` | 2.0 |
| `claude-sonnet-4.5` | 2.0 |
| `claude-sonnet-4.6` | 2.0 |
| `claude-opus-4.5` | 1.2 |
| `claude-opus-4.6`  | 1.1 |
| `claude-opus-4.7` | 1.1 |

### Features

The following table lists the number of executions you can make with one GitLab Credit for different features.
This pricing applies to all models (including self-hosted models) available for the feature.

| Feature | Executions with one credit |
|---------|---------------------------|
| [GitLab Duo Code Suggestions](../user/duo_agent_platform/code_suggestions/_index.md) | 50 |
| Code Review Flow | 4 |
| SAST False Positive Detection Flow | 1 |
| SAST Vulnerability Resolution Flow | 0.25 |

For GitLab Duo Agentic Chat, one sent message counts as one or more billable requests,
because one or more LLM calls are made to answer the question.
One conversation window can include multiple messages, and so multiple billable requests.
The pricing depends on the selected model.

## GitLab Credits dashboard

{{< details >}}

- Offering: GitLab.com, GitLab Self-Managed

{{< /details >}}

{{< history >}}

- Introduced in GitLab 18.7.
- Sorting results [introduced](https://gitlab.com/groups/gitlab-org/-/work_items/21008) in GitLab 18.10.

{{< /history >}}

The GitLab Credits dashboard displays information about your usage of GitLab Credits.
Use the dashboard to monitor credit consumption, track trends, and identify usage patterns.

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

On the dashboard, used credits represent deductions from available credits.
For overages (On-Demand credits), used credits represent on-demand usage that will be paid later,
if you have agreed to the usage billing terms.

The dashboard displays summary cards of key metrics:

- Current month usage: Total GitLab Credits used in the current month (if you have a monthly commitment)
- Included credits: Total credits included with your subscription (if you have a monthly commitment)
- Committed credits: Credits from your Monthly Committed Pool (if applicable)
- Monthly waivers: Remaining credits from waivers (if applicable)
- On-Demand usage: Credits consumed beyond your included and committed amounts.
  If you have enough waiver credits to offset all On-Demand credits, the GitLab Credits Dashboard hides
  the **On-Demand** card and displays the **Monthly Waiver** card instead.
- Usage control status: Whether individual users have been blocked from
  Agent Platform access due to reaching their per-user credit cap.

### In GitLab

> [!note]
> This dashboard displays usage of all GitLab Duo Agent Platform features, including non-billable
> beta and experiment features. For billable usage only, view the dashboard in Customers Portal.

The GitLab Credits dashboard in GitLab provides operational visibility into the usage of credits in your organization.
Use the dashboard to understand which users, groups, or projects are driving usage, and make informed decisions about resource allocation.

The dashboard displays the following information:

- **Organization usage**: Total credit usage across your GitLab instance or group
- **Total credit consumption**: Daily credit consumption over all products, displayed as a bar chart
- **Usage by user**: Number of credits used by each user
- **User drill-down view**: Individual usage events for each user, with links to GitLab Duo Agent Platform session details

### View the GitLab Credits dashboard

{{< history >}}

- Historical usage period selection [introduced](https://gitlab.com/gitlab-org/customers-gitlab-com/-/work_items/15910) in GitLab 18.11.

{{< /history >}}

{{< tabs >}}

{{< tab title="Customers Portal" >}}

Prerequisites:

- To view detailed usage information, you must be a billing account manager.

1. Sign in to [Customers Portal](https://customers.gitlab.com/).
1. On the subscription card, select **GitLab Credits dashboard**.
1. Optional. To view a previous month, from the **Usage period** dropdown list, select a period you want to view.
1. Optional. To sort the results by **User** or **Total credits used**, select the respective column.

{{< /tab >}}

{{< tab title="GitLab.com" >}}

Prerequisites:

- You must have the Owner role for the group.

1. In the top bar, select **Search or go to** and find your top-level group.
1. Select **Settings** > **GitLab Credits**.
1. Optional. To sort the results by **User** or **Total credits used**, select the respective column.

{{< /tab >}}

{{< tab title="GitLab Self-Managed" >}}

Prerequisites:

- You must be an administrator.
- Your instance must be able to synchronize your subscription data with GitLab.

1. In the upper-right corner, select **Admin**.
1. In the left sidebar, select **GitLab Credits**.
1. Optional. To sort the results by **User** or **Total credits used**, select the respective column.

{{< /tab >}}

{{< /tabs >}}

By default, individual user data is not displayed in the GitLab Credits dashboard.
To display it, you must enable this setting for your [group](../user/group/manage.md#display-gitlab-credits-user-data) or [instance](../administration/settings/visibility_and_access_controls.md#display-gitlab-credits-user-data).

### Non-human subject usage

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/work_items/596238) in GitLab 19.0.

{{< /history >}}

Credit consumption can be triggered by either a human user or a non-human subject,
such as a service account or a bot running an automated flow
(for example, the SAST False Positive Detection Flow or the
SAST Vulnerability Resolution Flow).

To help you identify where credits are consumed, the **Usage by user** tab
of the GitLab Credits dashboard displays an **Automated flow** badge next to
any row that represents a non-human subject. Rows without the badge represent
human users.

Non-human subjects do not receive [included credits](#included-credits).
All of their consumption is drawn from the namespace's Monthly Commitment Pool
first, and then from On-Demand credits, in the same [usage order](#usage-order)
as human users.

Display of **Automated flow** rows is controlled by the same setting as human-user
rows. To show them, enable [**Display GitLab Credits user data**](../user/group/manage.md#display-gitlab-credits-user-data)
for your group or [instance](../administration/settings/visibility_and_access_controls.md#display-gitlab-credits-user-data).

### Usage caps

{{< details >}}

- Status: Beta

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/work_items/19881) in GitLab 18.11 [with a feature flag](../administration/feature_flags/_index.md) named `budget_caps_graphql_api`. Enabled by default.

{{< /history >}}

> [!flag]
> The availability of this feature is controlled by a feature flag.
> For more information, see the history.

You can set a monthly GitLab Credits cap at the subscription and user level to prevent
unexpected overage charges. When credit consumption reaches the configured cap,
access to features that consume GitLab Credits (for example, GitLab Duo Agent Platform)
is automatically suspended until the next billing period begins,
or until an administrator adjusts or disables the cap.

The following cap types are available:

| Cap type | Applies to | Credit sources counted | Managed through |
|---|---|---|---|
| Subscription cap | All users on the subscription | On-Demand only | Customers Portal |
| Flat user cap | Individual users (default limit) | All | GraphQL API |
| Per-user override | Specific users (overrides the flat cap) | All | GraphQL API |

When on-demand usage in the current billing period reaches or exceeds the configured cap,
all Agent Platform features (Duo Chat, Code Suggestions, Flows, and Agents)
are suspended for all users on that subscription or instance. For user-level caps,
only the individual user who reached their cap is suspended.

Users who have reached their cap are unable to access Agent Platform features
until the cap is raised or the next billing period begins.

Usage counters reset automatically at the start of each billing period.
Cap values persist across billing periods unless changed.

Caps are enforced using the most recent usage data available. Because data
is not real time, limited additional GitLab Credits usage may occur before
enforcement takes effect.

When subscription on-demand usage reaches the configured cap, GitLab sends an
email notification to billing account managers.

#### Set a subscription-level usage cap

Prerequisites:

- You must be a billing account manager.

1. Sign in to [Customers Portal](https://customers.gitlab.com/).
1. On the subscription card, select **GitLab Credits dashboard**.
1. In the **On-demand Credit Cap** panel, turn on the **Monthly On-demand Credits cap** toggle.
1. Enter the maximum number of on-demand GitLab Credits allowed per billing period.
1. Select **Save**.

If the cap is set below the currently reported total on-demand usage
for the current billing period, the cap is considered reached immediately on
the next enforcement check.

To disable the cap, turn off the **Monthly On-demand Credits cap** toggle. When disabled,
no subscription-level on-demand GitLab Credits cap is enforced, and behavior falls back to
existing billing behavior.

You can use the GraphQL API to [view usage caps](../api/graphql/reference/_index.md#gitlabsubscriptionbudgetcaps) and set a [flat user-level cap](../api/graphql/reference/_index.md#mutationupsertflatusercap) or a [per-user override cap](../api/graphql/reference/_index.md#mutationupsertuserbudgetcapoverrides).

### Usage control status

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/work_items/594635) in GitLab 18.11.

{{< /history >}}

When per-user credit caps are enabled, the **Usage by user** tab on the
GitLab Credits dashboard displays a **Usage control status** column.
This column shows whether each user can access
[GitLab Duo Agent Platform](../user/duo_agent_platform/_index.md) features
or is blocked because they reached their credit cap.

The column displays one of the following statuses:

| Status | Description |
|--------|-------------|
| **Regular** | The user has not reached their credit cap and can use GitLab Duo Agent Platform features. |
| **Blocked - subscription cap reached** | The user reached the flat per-user cap set at the subscription level. |
| **Blocked - user cap reached** | The user reached a per-user override cap set specifically for them. |

#### Unblock a user who reached their credit cap

You can restore access for a blocked user by using the per-user override GraphQL API.

To unblock a user, either:

- Increase the cap: Set a higher per-user override cap so the user's
  usage falls below the new limit.
- Remove the cap: Delete the per-user override so the user is no longer
  subject to an individual cap.

After you update the cap, the user's status changes to **Regular** and they
can use GitLab Duo Agent Platform features again.

### View user credit usage details

{{< history >}}

- Linking to GitLab Duo Agent Platform session details [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/579139) in GitLab 18.10.

{{< /history >}}

To view a user's individual usage events in a drill-down view:

1. In the GitLab Credits dashboard, select the **Usage by user** tab.
1. In the **User** column, select the user you want to view.
1. To view session details, in the **Action** column, select the action you want to view.

> [!note]
> Session links are available only for GitLab Duo Agent Platform usage events that are triggered in a project and have an associated session ID.
> Usage events triggered in a group, legacy events, and actions outside Agent Platform don't have links.

### Export usage data

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/customers-gitlab-com/-/work_items/14504) in GitLab 18.10.

{{< /history >}}

You can export the credit usage data for a subscription as a CSV file in Customers Portal.
The CSV file lists the usage events and credits used on each day of the current month.

Prerequisites:

- You must be a billing account manager.

1. Sign in to [Customers Portal](https://customers.gitlab.com/).
1. On the subscription card, select **GitLab Credits dashboard**.
1. From the **Usage period** dropdown list, select the period you want to export data for.
1. Select **Export usage data**.
