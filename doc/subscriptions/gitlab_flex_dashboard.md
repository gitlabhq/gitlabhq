---
stage: Fulfillment
group: Utilization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: View and manage your GitLab Flex usage.
title: GitLab Flex Usage dashboard
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- Introduced in GitLab 19.1.

{{< /history >}}

The Flex Usage dashboard provides built-in tracking and reporting capabilities.

The dashboard displays:

- **Annual commitment and balance**: Total Flex commitment, year-to-date consumption, and remaining balance.
- **Monthly reservation**: Seat count, reserved credits, and on-demand spend for the current month.
- **Credit consumption by capability**: Breakdown of credits used for each usage-based product.
- **Credit consumption by project**: Top projects by credit usage.
- **Credit consumption by offering**: Usage split between GitLab.com, GitLab Self-Managed, GitLab Dedicated, and offline environments.
- **On-demand usage summary**: Month-to-date and year-to-date on-demand usage, and how much of it drew from your commitment.

## Usage and spend controls

To help you control how much you spend against your commitment, you can set spend caps (at the subscription level) and receive budget alerts.

### Spend caps

Per-capability caps limit how much a specific credit-based capability can consume, so one capability can't drain the shared pool.
When a capability hits its cap, usage stops while everything else keeps running.
The cap is per-product, not shared across the pool.
Because caps limit on-demand usage, they also slow how quickly you draw down your commitment.

Use per-capability caps for non-critical or experimental features you want to contain.

You can set the following per-capability caps:

- Restricted: No on-demand usage. Usage is blocked at the reservation, and the spend ceiling equals the reservation.
- Usage cap: Bounded on-demand usage. The spend ceiling is the reservation plus the capped amount.
- Unlimited: Unlimited on-demand usage. No spend ceiling.

Each capability has its own independent cap.
For example, you can cap GitLab Duo at $5,000 while leaving Artifact Registry unlimited.

### Usage notifications

GitLab sends emails as usage approaches and crosses specific limits, running on the existing budget-guardrail framework.
Subscription billing contacts receive dollar-based notifications, and namespace administrators receive credit-based notifications.

GitLab sends usage notifications when:

- A product crosses 50%, 80%, or 100% of its monthly reservation. At 100% the product starts on-demand usage.
- A product first incurs on-demand usage for the month. This usage draws from your total commitment at the list rate.
- A capped product crosses 50% or 80% of its cap (warning notification), or reaches 100% and is cut off (cut-off notification).

## View the Flex Usage dashboard

Prerequisites:

- You must be an administrator.

1. In the upper-right corner, select **Admin**.
1. In the left sidebar, select **Flex Usage**.

## Set a spend cap

To set a per-capability spend cap:

1. Sign in to [Customers Portal](https://customers.gitlab.com/).
1. Select **Flex dashboard**.
1. Select a month to display all capabilities.
1. In the row of the add-on you want to cap, from the **Spend Control** dropdown list, select a cap type.
   If you enter a value for the cap, it is converted to a dollar figure at that product's rate.
1. Review the reservation summary to confirm the caps are reflected in your add-ons subtotal and total.
1. Select **Save**.

## View daily usage by capability

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/customers-gitlab-com/-/merge_requests/16457) in GitLab 19.2.

{{< /history >}}

The GitLab Flex dashboard shows a daily usage chart for each capability in your reservation, including seats.
Use these charts to see how much of each capability you consumed on each day of a billing period.

The chart:

- Shows accumulated usage for each day of the billing period.
- Shows usage up to the current date for the current billing period.
- Displays the entire billing period, or only the prorated dates if your contract started or ended mid-period.
- Highlights in orange any on-demand usage, including seats above your reservation.

To view daily usage by capability:

1. Sign in to [Customers Portal](https://customers.gitlab.com/).
1. Select **Flex dashboard**.
1. In the **Month** column, select the current or a past month.
1. Select the tab for the capability you want to view.
