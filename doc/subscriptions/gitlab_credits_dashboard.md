---
stage: Fulfillment
group: Utilization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: View and manage your credit usage.
title: GitLab Credits dashboard
---

{{< details >}}

- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- Introduced in GitLab 18.7.
- Sorting results [introduced](https://gitlab.com/groups/gitlab-org/-/work_items/21008) in GitLab 18.10.

{{< /history >}}

The GitLab Credits dashboard displays information about your usage of GitLab Credits.
Use the dashboard to monitor credit consumption, track trends, and identify usage patterns.

To help you manage credit consumption, GitLab emails the following information to
Customers Portal users linked to the billing account:

- Monthly credit usage summaries
- Notifications when credit usage thresholds are at 50%, 80%, and 100%

You can access the dashboard in the Customers Portal and in GitLab.
On GitLab Dedicated, the dashboard is available in the Customers Portal and to instance administrators.
Group-level and personal credit usage views are available on GitLab.com only.

> [!note]
> Usage data is not displayed in real time.
> Data is synchronized to the dashboards periodically, so usage data should appear within a few hours of actual consumption.
> This means your dashboard shows recent usage, but might not reflect actions taken in the last few hours.

## In Customers Portal

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

## In GitLab

{{< history >}}

- Secrets Manager usage introduced in GitLab 19.1.

{{< /history >}}

> [!note]
> This dashboard displays usage of all credit-based features, including non-billable
> beta and experiment features. To view billable usage only, go to the Customers Portal.
>
> Some pre-release features, such as the Security Review Flow, are billable and subject to
> GitLab Credits charges.

The GitLab Credits dashboard in GitLab provides operational visibility into the usage of credits in your organization.
Use the dashboard to understand which users, groups, or projects are driving usage, and make informed decisions about resource allocation.

The dashboard displays the following information:

- **Organization usage**: Total credit usage, active users, daily credit average, and peak day usage across your GitLab instance or group
- **Total credit consumption**: Daily credit consumption over all products, displayed as a bar chart
- **Usage by user**: Number of credits used by each user
- **User drill-down view**: Individual usage events for each user, with links to session details for each credit-based feature
- **Usage by product**: Number of credits used and percentage of total credits for credit-based features

> [!note]
> While [GitLab Secrets Manager](../ci/secrets/secrets_manager/_index.md) is in beta,
> GitLab does not bill for usage. Secrets Manager appears in the Credits dashboard
> but displays no usage data until the beta period ends.

## View the GitLab Credits dashboard

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

## Non-human subject usage

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/work_items/596238) in GitLab 19.0.

{{< /history >}}

Credit consumption can be triggered by either a human user or a non-human subject
(for example, an AI feature like the SAST False Positive Detection Flow).

To help you identify where credits are consumed, the **Usage by user** tab
on the GitLab Credits dashboard displays an **Automated flow** badge next to
the rows that represent non-human subjects.
Rows without the badge represent human users.

The display of the **Automated flow** badge is controlled by the setting **Display GitLab Credits user data**,
which is available for [groups](../user/group/manage.md#display-gitlab-credits-user-data)
and [instances](../administration/settings/visibility_and_access_controls.md#display-gitlab-credits-user-data).

## Usage caps

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/work_items/19881) in GitLab 18.11 [with a feature flag](../administration/feature_flags/_index.md) named `budget_caps_graphql_api`. Enabled by default.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/work_items/607551) in GitLab 19.3. Feature flag `budget_caps_graphql_api` removed.

{{< /history >}}

You can set a monthly GitLab Credits cap at the subscription and user level to prevent
unexpected overage charges. When credit consumption reaches the configured cap,
access to credit-based features
is automatically suspended until the next billing period begins,
or until an administrator adjusts or disables the cap.

The following cap types are available:

| Cap type | Applies to | Credit sources counted | Managed through |
|---|---|---|---|
| Subscription cap | All users on the subscription | On-Demand only | Customers Portal |
| Flat user cap | Individual users (default limit) | All | GraphQL API |
| Per-user override | A specific user's total usage, including their included credits. Overrides the flat cap. A user can therefore consume up to whichever is larger: their included allocation, or their cap. | All | GraphQL API |

When on-demand usage in the current billing period reaches or exceeds the configured cap,
all credit-based features
are suspended for all users on that subscription or instance, and GitLab sends an email notification to billing account managers. For user-level caps,
only the individual user who reached their cap is suspended.

Flat user caps and per-user override caps apply to usage beyond a user's included allocation.
While a user still has included credits, they can continue to consume their included credits
even after their usage reaches the cap.
The cap is enforced only after the user's included credits are exhausted.

Users who have reached their cap are unable to access Agent Platform features
until the cap is raised or the next billing period begins.

Usage counters reset automatically at the start of each billing period.
Cap values persist across billing periods unless changed.

Caps are enforced using the most recent usage data available. Because data
is not real time, limited additional GitLab Credits usage may occur before
enforcement takes effect.

Caps do not stop users from consuming their included GitLab Credits. Enforcement begins per user, and only after that user's included allocation is exhausted. Until then, the user retains full GitLab Duo Agent Platform access regardless of the cap value, including a cap of `0`.

To stop all GitLab Credits consumption immediately, regardless of included
balances, disable GitLab Duo for the affected users or namespace.

How the cap value is applied then depends on the cap type:

- A **subscription-level cap** applies to on-demand usage only. The cap is the amount of on-demand usage allowed across the subscription, in addition to every user's included credits.
- A **per-user cap** applies to a user's total usage, including their included credits. A user can therefore consume up to whichever is larger: their included allocation, or their cap.

### Examples

For a subscription-level cap, consider a subscription that has 10 users, each with 100 included GitLab Credits. The billing account manager sets the subscription-level on-demand cap to `0`.

- A user who has already used all 100 of their included credits is blocked from Agent Platform features immediately (on the next enforcement check), because any further usage would be on-demand.
- A user who has only used 40 of their included credits can continue using Agent Platform features and consume their remaining 60 included credits. The `0` cap does not apply to them yet.

For a per-user cap, consider a user that has 24 included GitLab Credits.

- With a per-user cap of `50`, the user is blocked after 50 credits in total, 26 credits beyond their included allocation.
- With a per-user cap of `10`, the user is blocked after 24 credits, when their included allocation is exhausted.

### Set a subscription-level usage cap

Prerequisites:

- You must be a billing account manager.

1. Sign in to [Customers Portal](https://customers.gitlab.com/).
1. On the subscription card, select **GitLab Credits dashboard**.
1. Select **Spend controls**.
1. In the **On-demand credit cap** panel, turn on the **Set on-demand credit cap** toggle.
1. Enter the maximum number of on-demand GitLab Credits allowed per billing period.
1. Select **Save Changes**.

If the cap is set below the currently reported total on-demand usage
for the current billing period, the cap is considered reached immediately on
the next enforcement check.

To disable the cap, turn off the **Set on-demand credit cap** toggle. When disabled,
no subscription-level on-demand GitLab Credits cap is enforced, and behavior falls back to
existing billing behavior.

You can use the GraphQL API to [view usage caps](../api/graphql/reference/_index.md#gitlabsubscriptionbudgetcaps) and set a [flat user-level cap](../api/graphql/reference/_index.md#mutationupsertflatusercap) or a [per-user override cap](../api/graphql/reference/_index.md#mutationupsertuserbudgetcapoverrides).

## Usage control status

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/work_items/594635) in GitLab 18.11.

{{< /history >}}

When per-user credit caps are enabled, the **Usage by user** tab on the
GitLab Credits dashboard displays a **Usage control status** column.
This column shows whether each user can access
credit-based features
or is blocked because they reached their credit cap.

The **Usage control status** column displays the status **Blocked usage** only when GitLab enforces the cap against the user.
GitLab enforces the cap after the user's included credits are exhausted.
A user who has reached their cap but still has included credits has the status **Regular usage**,
because they can continue to consume their included credits.

The column displays one of the following statuses:

| Status | Description |
|--------|-------------|
| **Regular usage** | The user has not reached their credit cap, or has reached their cap but still has included credits, and can use GitLab Duo Agent Platform features. |
| **Blocked usage** | The user has exhausted their included credits and reached their per-user cap. The cap is either the flat user cap set for all users on the subscription, or a per-user override cap set specifically for them. |

The dashboard does not display which type of cap blocked a user.
To determine the cap type, use the [GraphQL API](../api/graphql/reference/_index.md#gitlabsubscriptionusageblockedstatus).

The **Usage control status** column displays only per-user caps.
The subscription-level on-demand cap applies to the entire subscription, not to individual users, and is not listed in this column.

### Unblock a user who reached their credit cap

You can restore access for a blocked user by using the per-user override GraphQL API.

To unblock a user, either:

- Increase the cap: Set a higher per-user override cap so the user's
  usage falls below the new limit.
- Remove the cap: Delete the per-user override so the user is no longer
  subject to an individual cap.

After you update the cap, the user's status changes to **Regular usage** and they
can use credit-based features again.

## View user credit usage details

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

## Export usage data

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
