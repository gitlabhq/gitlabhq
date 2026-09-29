---
stage: Fulfillment
group: Utilization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: View your GitLab Flex commitment and usage, adjust your reservation, and control your spend.
title: Flex dashboard
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- Introduced in GitLab 19.1.

{{< /history >}}

The Flex dashboard is where you track your [GitLab Flex](gitlab_flex.md) commitment and usage, set your monthly reservation, and control your spend.

## Panels

The Flex dashboard has two levels. The main page shows your commitment across the whole contract term. Selecting a month shows your usage and reservation for that month.

### Contract term

The main page displays:

- **Contractual commitment**: Your total commitment for the contract term, how much you have used to date, and how much remains.
- **On-demand spend**: Your total on-demand spend for the contract term.
- **Contract term**: Your contract start and end dates, which billing period you are in, and your minimum monthly reservation.

Below these, a table lists every month of your contract term:

- **Month**: The billing period. Select a past, current, or upcoming month to view it in detail.
- **Status**: Where the month is in your contract term:
  - **Past month** and **Current month**: The reservation is locked.
  - **Upcoming**: The next month. This is the only month whose reservation you can change.
  - **Future month**: Months after the upcoming month. These are locked until they become the upcoming month.
- **Reserve by**: Set the reservation for that month before this date.
- **Reserved**: The amount reserved for that month.
- **On-demand**: On-demand usage for that month.
- **Actual spend**: Your reservation plus on-demand usage.

### Month overview

Select the current or a past month to see your usage against that month's committed reservation.

The month overview displays:

- **Total monthly reservation**: The amount reserved for the month, split between seats and credit capabilities.
- **Seats**: Seats used against your reservation.
- **GitLab Credits**: Credits used for the month per capability, split between credits drawn from your reservation and on-demand credits.

A table breaks down each capability in your reservation, showing the amount reserved, any on-demand usage, and your actual spend.

## View the Flex dashboard

Prerequisites:

- You must be a billing account manager.

To view the Flex dashboard:

1. Sign in to [Customers Portal](https://customers.gitlab.com/).
1. Go to the **Subscriptions & purchases** page.
1. On the relevant subscription card, select **Flex dashboard**.

### View daily usage by capability

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/customers-gitlab-com/-/merge_requests/16457) in GitLab 19.2.

{{< /history >}}

The month overview has a tab for each capability in your reservation, including seats. Use these tabs to see how much of each capability you consumed on each day of a billing period.

The chart:

- Shows accumulated usage for each day of the billing period.
- Shows usage up to the current date for the current billing period.
- Displays the entire billing period, or only the prorated dates if your contract started or ended mid-period.
- Highlights in orange any on-demand usage, including seats above your reservation.

To view daily usage by capability:

1. Open the Flex dashboard.
1. In the **Month** column, select the current or a past month.
1. Select the tab for the capability you want to view.

## Reservation management

Your reservation is what you commit to for a single calendar month. You can change it for the upcoming month without a contract amendment.

Your reservation has two parts:

- **Platform access**: The seats you reserve for the month, at your negotiated per-seat rate.
- **Add-ons**: The credits you reserve for each credit-based capability, at your Flex discount. If you reserve no credits for a capability, you pay list price for what you consume.

Before you change a reservation, review the [conditions that apply](gitlab_flex.md#monthly-reservation-changes), including the deadline shown in the **Reserve by** column and the limit on how much you can reserve.

### Adjust your reservation

To adjust your reservation for the upcoming month:

1. Open the Flex dashboard.
1. In the **Month** column, select the month with the **Upcoming** status.
1. Under **Platform access**, update the number of **seats**.
1. Under **Add-ons**, update the number of **credits** for each capability.
1. Select **Save reservation**.

The reservation page shows your average usage for each capability (when available), so you can size your reservation against what you have been consuming.

After you save, a success message confirms the update. The Flex dashboard shows the new reserved amounts, which apply from that month onward until you change them again.

You can update your reservation as many times as you want before its **Reserve by** date. Only the most recent saved value takes effect. After a month begins, its reservation is locked.

## Spend management

By default, your reservation is not a spending limit. Usage above your reservation accrues as on-demand usage and draws from your remaining Flex balance. To limit that, set spend controls and watch for usage notifications.

### Spend controls

A spend control limits how much a single capability can consume above its reservation, so one capability cannot drain your balance. Spend controls are set per capability, so limiting one capability does not affect the others. Some capabilities are always-on and cannot be capped. In the **Spend control** column, these show **Unlimited** as text instead of a dropdown list, and their usage above the reservation is charged at list price.

You can set:

- **Restricted**: No on-demand usage. Usage stops at the reservation, and the spend ceiling equals the reservation.
- **Usage cap**: Bounded on-demand usage. The spend ceiling is the reservation plus the capped amount.
- **Unlimited**: Unlimited on-demand usage. No spend ceiling.

By default, the **Spend control** dropdown list for a capability is set to **Unlimited**.

When a capability reaches its limit, usage of that capability stops. Everything else keeps running. For example, you can cap GitLab Duo Agent Platform and leave other capabilities unlimited.

Because spend controls limit on-demand usage, they also slow how quickly you draw down your commitment. Use them for capabilities you want to contain, such as non-critical or experimental features.

Unlike seats and credits, spend controls can be changed mid-month. If a capability has been stopped, you can raise or remove its spend control to resume usage in the current month.

#### Set a spend control

You can set spend controls for the current month or the upcoming month.

To set a spend control for the current month:

1. Open the Flex dashboard.
1. In the **Month** column, select the month with the **Current month** status.
1. Select **Manage spend controls**.
1. Under **Add-ons**, in the row of the capability you want to limit, from the **Spend control** dropdown list, select a type.
1. If you selected **Usage cap**, enter the number of credits to allow above the reservation. This is converted to a dollar figure at that capability's rate.
1. Review the reservation summary to confirm the spend controls are reflected in your add-ons subtotal and total.
1. Select **Save**.

To set a spend control for the upcoming month:

1. Open the Flex dashboard.
1. In the **Month** column, select the month with the **Upcoming** status.
1. Under **Add-ons**, in the row of the capability you want to limit, from the **Spend control** dropdown list, select a type.
1. If you selected **Usage cap**, enter the number of credits to allow above the reservation. This is converted to a dollar figure at that capability's rate.
1. Select **Save reservation**.

### Usage notifications

GitLab sends emails as your usage approaches and crosses your limits.

GitLab sends a usage notification when:

- A capability crosses 50%, 80%, or 100% of its monthly reservation. At 100%, the capability starts on-demand usage.
- A capability first incurs on-demand usage for the month. This usage draws from your total commitment at the list rate.
- A capability with a spend control crosses 50% or 80% of its limit, or reaches 100% and is stopped.

### Per-user credit limits

Spend controls limit consumption for an entire capability. To limit how many credits an individual user can consume, [configure per-user credit limits in GitLab](gitlab_credits_dashboard.md#manage-credit-caps).
