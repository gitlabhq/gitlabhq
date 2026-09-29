---
stage: Fulfillment
group: Utilization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Understand how GitLab Flex works and manage your reservation.
title: GitLab Flex
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- Introduced in GitLab 19.1.

{{< /history >}}

GitLab Flex is a purchasing model that covers your entire GitLab spend with a single annual commitment.

You commit to a dollar amount for the year based on your projected spend. That commitment becomes a balance you draw down as you use GitLab, at the rates set in your Flex agreement.

Each month you reserve the seats and GitLab Credits you expect to use, and GitLab draws the cost of that reservation down from your balance. Usage above your reservation also draws from your balance, with credits charged at list rate and seats at your negotiated rate. Once your balance is exhausted, GitLab invoices you directly.

You choose how much to reserve each month in the [Flex dashboard](gitlab_flex_dashboard.md), and you can change it without a new contract or amendment.

> [!note]
> Flex purchases are governed by their own billing terms for seats and usage, which take precedence over the GitLab Subscription Agreement where the two conflict.
> The standard add-on user and overage user billing processes do not apply to Flex. They continue to apply to any non-Flex subscriptions you hold.

For a click-through demo, see [GitLab Flex](https://click-through-demo-generator-v-2-d63870.gitlab.io/demos/flex/).
<!-- Demo published on 2026-07-08 -->

## Availability

GitLab Flex is available on GitLab.com, GitLab Self-Managed, and GitLab Dedicated.

> [!note]
> For GitLab Dedicated, the administration fee and storage are billed separately and do not draw from your Flex balance.

### Multiple instances

{{< details >}}

- Offering: GitLab Self-Managed

{{< /details >}}

You can use a single Flex commitment across multiple GitLab Self-Managed instances by applying the same activation code or license file to each instance.

GitLab aggregates usage across your instances:

- Seats are counted as the high watermark across all instances combined.
- Credit consumption is totaled across all instances.

Your reservation and balance remain a single pool. You do not allocate portions of your commitment to individual instances.

### Offline environments

{{< details >}}

- Offering: GitLab Self-Managed

{{< /details >}}

GitLab Flex is available for offline environments. You manage your reservation in the Flex dashboard in the same way as any other Flex subscription.

Because offline instances do not sync usage to GitLab, two things differ:

- You report seat usage manually, following the process for [license usage in offline environments](../administration/license_usage.md).
- Credit usage is reconciled twice a year through a sales-assisted true-up process.

## Capabilities available with GitLab Flex

Your Flex commitment covers your GitLab seats and credit-based capabilities.

You can use [credit-based features](gitlab_credits.md#features) with GitLab Flex.

You enable a capability the same way as any other GitLab feature, and no contract change or amendment is required. For enablement steps, see the documentation for that capability.

Enabling a capability and reserving credits for it are separate actions. If you enable a capability without reserving credits, its usage is on-demand and draws from your balance at the list rate. To get your discounted rate, [reserve credits](gitlab_flex_dashboard.md#adjust-your-reservation) for that capability for the upcoming month.

## Monthly reservations

A reservation is what you commit to for a single calendar month:

- **Seats**: The number of users who need access to GitLab, at the per-seat rate negotiated with your GitLab account team. That rate applies to every seat, whether or not it is reserved.
- **Credits**: A monthly pool of GitLab Credits for each credit-based capability, at your discounted per-credit rate. Credits are reserved for each capability separately.

You can change your reservation for the upcoming month without a contract amendment. Reserving credits accurately matters in both directions: reserve too few and you pay list rate for the difference, reserve too many and the unused credits expire.

Your first month's reservation is set as part of your contract. If your contract is future-dated, you can change that reservation in the Flex dashboard before your first month begins.

Reservations carry over from month to month. If you take no action, your current reservation applies again next month.

### Minimum required reservation

Your contract sets a minimum required reservation, which is the lowest monthly amount you can reserve. Changing it requires a contract amendment.

This amount is drawn from your prepaid commitment each month of your term.

If your commitment is exhausted before your term ends, GitLab invoices you directly for the minimum required reservation each remaining month, because no balance remains to debit it from.

Your minimum required reservation is shown on the Flex dashboard.

### Monthly reservation changes

You can change your monthly reservation for the upcoming month in the Flex dashboard, without a contract amendment. The following conditions apply:

- Changes take effect at month boundaries. You cannot change a reservation mid-month. After a month begins, that month's reservation is final and you cannot adjust it.
- Changes are due by the second-to-last day of the month. Submit changes before 11:59 PM UTC on the second-to-last day of the current month to apply them to the next month. For example, submit changes by July 30 to apply them to August. In the Flex dashboard, submit changes before the date shown in the **Reserve by** column for that month.
- Your reservation cannot exceed your monthly commitment amount. This is your annual commitment divided by 12.
- Your minimum required reservation is fixed. You cannot change the minimum monthly reservation fixed in your contract. This amount remains due for each remaining month of your term, even if your commitment is exhausted before the term ends.
- Seat tier changes require a contract amendment. To change between Premium and Ultimate, contact your GitLab account team. A tier change takes effect on the first of the month and cannot be applied mid-month.

Spend controls are the exception to the month-boundary rule. You can change a spend control for the current month at any time.

## On-demand usage

Usage above your monthly reservations is on-demand usage. Usage draws from your monthly reservation first, then accrues as on-demand once the reservation is used up.

While balance remains in your annual commitment, on-demand usage draws from that balance at the [list rate](gitlab_credits.md#on-demand-credits), and GitLab does not invoice it separately. GitLab invoices on-demand usage only after your commitment is fully exhausted.

Because all usage draws from the same annual balance, on-demand usage in one month reduces the balance available for later months. Your remaining balance can become less than the total of the minimum required reservations for the months left in your term.

To track your remaining balance, use the Flex dashboard.

## The monthly cycle

Flex runs on calendar months.

At the start of the month, your reserved seats and credits become available to use, and GitLab debits the cost of your reservation from your balance at your discounted rate.

During the month, each user's included credit allocation is consumed first, then your reserved credits. When your reservation is used up, further usage accrues as on-demand at list rate.

At the end of the month, any unused reserved credits expire. Seats are charged at the highest count reached during the month, so seats above your reservation draw from your balance at your per-seat rate.

If your subscription starts mid-month, your first and last months are prorated and cover only the days remaining in those calendar months.

## Exhausted commitments

Your Flex balance is exhausted when your cumulative drawdown equals your total annual commitment. Depending on your consumption, this can happen before the end of your contract term.

After your balance reaches zero, for each remaining month of your term:

- Direct invoicing begins. GitLab invoices monthly to the payment method on file or otherwise in accordance with your applicable payment terms.
- Your minimum required reservation is still due. Because no balance remains to debit it from, GitLab invoices you directly for the minimum required reservation fixed in your contract.
- On-demand usage is invoiced on top. GitLab invoices any on-demand usage in addition to that reservation.

To control consumption and avoid on-demand invoicing, use [spend controls](gitlab_flex_dashboard.md#spend-management) and usage notifications to manage your spend. If your consumption is outpacing your commitment, contact your GitLab account team to discuss your options for the remainder of your term.

## Buy GitLab Flex

GitLab Flex is available as an annual or multi-year term. To buy GitLab Flex, contact your GitLab account team or the [GitLab Sales team](https://about.gitlab.com/sales/).

Your total annual commitment should account for:

- Seats: Number of users × seat tier price (Premium or Ultimate) × 12 months.
- Usage: Estimated monthly consumption for credit-based capabilities × 12 months.
- Growth: Additional capacity for mid-year expansion or new capability adoption.

Each year of a multi-year contract is a separate Flex term with its own contractual commitment amount. Unused balance does not carry over between Flex terms.

Tiered volume discounts are applied automatically based on your total commitment. The higher your commitment, the lower your per-credit rate, so a larger commitment covers more credits rather than costing less.

### Activate your subscription

After you sign your Flex agreement, activate your subscription for [GitLab.com](manage_subscription.md#link-subscription-to-a-group) or [GitLab Self-Managed](../administration/license.md#activate-gitlab-ee).

## Renew GitLab Flex

You can renew your GitLab Flex commitment for a one-year or multi-year term in collaboration with your GitLab account team.

Before the end of your contract, your GitLab account team contacts you to begin renewal discussions. Based on your year-to-date consumption, on-demand usage patterns, capacity needs, and growth projections, you can choose to increase or decrease your total commitment. Your new volume discount tier is based on the renewed commitment amount.
