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

GitLab Flex is a purchasing model that covers all GitLab capabilities with a single commitment.
You can adjust your seats and credits reservation month-to-month, without additional contracts or amendments.

You commit to an annual dollar amount based on your projected GitLab spend.
This commitment creates a balance that you draw down from as you consume seats and credits
for credit-based capabilities, priced according to the [GitLab Rate Card](https://about.gitlab.com/pricing/).

GitLab Flex is also available for offline environments.

> [!note]
> GitLab Flex subscriptions are governed by their own billing terms for seats and usage.
> The standard add-on user and overage user billing processes described in the GitLab Subscription Agreement do not apply to Flex purchases.
> If any Flex terms conflict with the GitLab Subscription Agreement, Flex terms take precedence for your purchase.
> Standard billing terms continue to apply to non-Flex subscriptions.

For a click-through demo, see [GitLab Flex](https://click-through-demo-generator-v-2-d63870.gitlab.io/demos/flex/).
<!-- Demo published on 2026-07-08 -->

## Offerings

| | GitLab.com | GitLab Self-Managed | GitLab Dedicated | Offline environments |
|---|---|---|---|---|
| **Metering** | Credit usage is tracked and debited daily. | Credit usage is synced to GitLab servers daily. | Credit usage is tracked by GitLab. | Credit usage is tracked locally and reported twice a year. |
| **Provisioning** | Is instant, changes apply within minutes. | Requires cloud licensing enabled on your instance. | Requires coordination with your GitLab account team. | GitLab generates and delivers license files. |
| **Billing** | Reservations debit your balance on the last day of the calendar month. On-demand usage from the prior month debits your balance at the start of the next month. | Reservations debit your balance on the last day of the calendar month. On-demand usage from the prior month debits your balance at the start of the next month. | Reservations debit your balance on the last day of the calendar month. On-demand usage from the prior month debits your balance at the start of the next month. <sup>1</sup> | Reservations debit your balance on the last day of the calendar month. Actual usage is reconciled twice a year through [true-up](quarterly_reconciliation.md#annual-true-up). |
| **On-demand invoicing** | Begins only after your commitment is exhausted. Auto-billed monthly to the payment method on file, or otherwise invoiced in accordance with your applicable payment terms. | Begins only after your commitment is exhausted. Auto-billed monthly to the payment method on file, or otherwise invoiced in accordance with your applicable payment terms. | Begins only after your commitment is exhausted. Auto-billed monthly to the payment method on file, or otherwise invoiced in accordance with your applicable payment terms. | Begins only after your commitment is exhausted. Invoiced twice a year based on reported usage. |

**Footnotes:**

1. The administration fee and storage are billed separately and do not draw from your GitLab Flex commitment.

## Monthly drawdown cycle

GitLab Flex operates on a monthly drawdown cycle based on calendar month.

- Beginning of the month
  - Seat count is set: GitLab sets your reserved seat count for the month; seats are charged at month end.
  - Capabilities become active: GitLab enables the capabilities you provisioned.
  - Reserved credits become available: Your monthly credit pool is ready to use.
  - Prior month's on-demand usage is settled: GitLab debits it from your remaining Flex balance at the list rate, or invoices it directly if your commitment is exhausted.
- During the month
  - Usage is tracked: GitLab meters your credit consumption in real time for usage-based products.
  - Reserved credits are consumed first: Usage draws from your monthly reserved pool.
  - On-demand usage accrues: Usage above the reserved pool accrues at the list rate.
- End of the month
  - Reservation is debited: GitLab draws down your reserved credit pool and any reserved add-ons from your Flex balance at your discounted Flex rate. This is not invoiced separately.
  - Unused reserved credits expire: Unused credits do not roll over.
  - Seats are charged at the monthly peak: GitLab charges for the highest seat count reached during the month. Seats above your reservation are charged at your per-seat rate and draw from your remaining Flex balance.
  - On-demand usage is totaled: The total is debited from your remaining Flex balance at the start of the next month, or invoiced directly if your commitment is exhausted.

At the beginning of the next month, the drawdown cycle repeats with a new monthly reservation.

### On-demand usage

Your monthly reservation is not a spending limit, and GitLab does not hold it separately from the rest of your commitment.

Usage above your monthly reservation is on-demand usage.

While balance remains in your commitment, on-demand usage draws from that balance at the list rate on the GitLab Rate Card,
and GitLab does not invoice it separately.
GitLab invoices on-demand usage only after your commitment is fully exhausted.

Because all usage draws from the same annual balance, on-demand usage in one month reduces the balance
available for later months.
Your remaining balance can become less than the total of the minimum required reservations for the
months left in your term.

To track your remaining balance, see the Flex Usage dashboard.

### After your commitment is exhausted

Your Flex balance is exhausted when your cumulative drawdown equals your total annual commitment.
Based on your consumption, this can happen before the end of your contract term.

After your balance reaches zero, for each remaining month of your term:

- On-demand invoicing begins: GitLab invoices all on-demand usage at the list rate, either monthly to
  the payment method on file or otherwise in accordance with your applicable payment terms.
- Your minimum required reservation is still due: Because no balance remains to debit it from,
  GitLab invoices you directly for the minimum required reservation fixed in your contract.
- On-demand usage is invoiced on top: GitLab invoices any on-demand usage in addition to that reservation.

To control consumption and avoid on-demand invoicing, use spend caps and usage notifications.
If your consumption is outpacing your commitment, contact your GitLab account team to
discuss your options for the remainder of your term.

## Volume discounts

Tiered volume discounts are automatically applied based on your total Flex commitment amount.
The volume discount does not reduce your commitment value, the reserved credits are debited from your Flex balance at this discounted rate.
The higher your commitment, the lower your reserved per-credit rate.
The per-user effective price is a separate component and is determined independently of your volume discount tier.

The volume discount applies only to your reservation.
On-demand usage draws from your balance at the list rate.

## Buy GitLab Flex

GitLab Flex is available as a recurring annual or multi-year term, for full annual terms of 12 months.
To buy GitLab Flex, contact your GitLab account team or the [GitLab Sales team](https://about.gitlab.com/sales/).

Your total commitment should account for:

- Base seat costs: Number of users × seat tier price (Premium or Ultimate) × 12 months.
- Expected credit usage: Estimated monthly consumption for credit-based capabilities × 12 months.
- Growth buffer: Additional capacity for mid-year expansion or new capability adoption.

Tiered volume discounts are available and automatically applied based on your total commitment size.

Multi-year contracts operate as separate annual pools.
This means that an unused balance in one year does not carry over to the following year.
For a multi-year term, your total commitment is the amount for a single year, not the sum of all years.

After you sign your GitLab Flex agreement, you can start provisioning your initial reservation.

## Provisioning

You can provision and change your reservation in Customers Portal.
If provisioning is successful, GitLab sends an email confirmation with the reservation information to the subscription ("Sold to") contact.

- On GitLab.com, changes are synced to the namespace.
- On GitLab Self-Managed and GitLab Dedicated, you receive an [activation code](../administration/license.md) for your instance.

All future reservations are automatically synced to the namespace or instance used in the initial setup.

### Monthly reservation

After you sign your GitLab Flex agreement, you can set your initial monthly reservation from the Flex dashboard.

The reservation management page displays:

- **Minimum required reservation**: The minimum monthly dollar amount fixed in your contract. This amount is due for every month of your contract term, including any months after your commitment is exhausted.
- **Maximum reservation**: The maximum monthly dollar amount available based on your remaining balance.
- **Seats**: The number of seats to reserve for the month.
- **Credits (DAP)**: The number of GitLab Credits (Duo Agent Platform) to reserve for the month.

### Adjust your reservation

You can adjust your Flex reservation month-to-month without contract amendments:

- Seat count: Increase or decrease the number of seats.
- Reserved credit pool: Increase or decrease your monthly use-it-or-lose-it credit reservation.
- Spend control: Adjust the caps that limit on-demand usage for each capability.

Prerequisites:

- You must be a billing account manager.

To adjust your reservation for an upcoming billing period:

1. Sign in to [Customers Portal](https://customers.gitlab.com/).
1. Select **Flex dashboard**.
1. Select the upcoming billing period, which is marked as editable.
1. On the reservation management page, update the number of **Seats** and **Credits** (for Duo Agent Platform).
1. Select **Save reservation**.

After you save, a success message confirms the update. The Flex dashboard shows the new reserved amounts, which apply from the next billing period onward until you change them again.

You can update your reservation as many times as you want before the next billing period begins. Only the most recent saved value takes effect on the 1st of the month.

#### Credits reservation

If you set the number of **Credits** for GitLab Duo Agent Platform to `0`, no credits are reserved for that billing period.
All credit usage in that period is on-demand usage.
All credit usage in that period is on-demand usage, drawn from your remaining Flex balance at the list rate and invoiced only if your commitment is exhausted.

#### Reservation adjustment conditions

The following adjustment conditions apply:

- Changes must fit within your monthly starting commitment. This is your initial total commitment divided by number of months in your contract term.
  For example, if your annual commitment is $120,000, your monthly starting commitment is $120,000 / 12 = $10,000. Each month, your reservation changes must not exceed $10,000. If you have a 2-year subscription, the monthly starting commitment is still $10,000, based on the $120,000 annual term, not the $240,000 combined total divided by 24 months.
- Due date for changes is the second-to-last day of the month. You must submit changes before 11:59 PM UTC on the second-to-last day of the current month to apply them to the next month.
  For example, you must submit changes by July 30th so that they apply to the month of August.
  After a month begins, that month's reservation is final and you can't reduce, reverse, or prorate it.
- Seat and reservation changes only take effect at month boundaries.
  You can't change your reservation mid-month.
- Offering is fixed. You can't change the offering selected in your contract.
- Minimum monthly reservation is fixed. You can't change the required monthly reservation fixed in your contract.
  This amount remains due for each remaining month of your term, even if your commitment is exhausted before the term ends.
- Seat tier changes require contract amendment.
  If you want to change between Premium and Ultimate tiers, contact your GitLab account team.
  A tier change takes effect on the first of the month and cannot be applied mid-month.

#### Troubleshooting

The following errors prevent a reservation from being saved:

##### Error: `Invalid value`

The seat or credits quantity is negative.

To resolve this issue, enter a whole number of `0` or greater.

##### Error: `Seats cannot be zero`

The seat quantity is set to `0`.

To resolve this issue, enter a seat count of at least `1`.

##### Error: `Below minimum reservation`

The total reservation value (seats plus credits) is less than the minimum required reservation shown at the top of the page.

To resolve this issue, increase the number of seats or credits until the total meets the minimum.

##### Error: `Above maximum reservation`

The total reservation value (seats plus credits) is greater than the maximum reservation shown at the top of the page.

To resolve this issue, decrease the number of seats or credits until the total does not exceed the maximum.

## Renew GitLab Flex

You can renew your GitLab Flex commitment for a one-year or multi-year term in collaboration with the GitLab account team.

90 days before the end of your contract, your GitLab account team contacts you to begin renewal discussions.
Based on your year-to-date consumption, on-demand usage patterns, capacity needs, and growth projections,
you can choose to increase or decrease your total commitment.
The new volume discount tier is based on the renewed commitment amount.
