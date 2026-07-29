---
stage: Fulfillment
group: Utilization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Understand how GitLab Flex works and manage your allocation.
title: GitLab Flex
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- Introduced in GitLab 19.1.

{{< /history >}}

GitLab Flex is a purchasing model that provides a single annual dollar commitment that covers all GitLab capabilities.
You can adjust your seat allocation and GitLab Credits month-to-month, without additional contracts or amendments.

With GitLab Flex, you commit to an annual dollar amount based on your projected GitLab spend.
This commitment creates an annual balance that you draw down from as you consume seats and credits for credit-based capabilities,
priced according to the [GitLab Rate Card](https://about.gitlab.com/pricing/).

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
| **Billing** | Reservations debit at month start. Per-use and overage debit as consumed. | Reservations debit at month start. Per-use and overage debit as consumed. | Reservations debit at month start. Per-use and overage debit as consumed. <sup>1</sup> | Reservations debit at month start. Actual usage is reconciled twice a year through [true-up](quarterly_reconciliation.md#annual-true-up). |
| **Overage handling** | Auto-billed monthly to the payment method on file, or otherwise invoiced in accordance with your applicable payment terms. | Auto-billed monthly to the payment method on file, or otherwise invoiced in accordance with your applicable payment terms. | Auto-billed monthly to the payment method on file, or otherwise invoiced in accordance with your applicable payment terms. | Invoiced twice a year based on reported usage. |

**Footnotes:**

1. The administration fee and storage are billed separately and do not draw from your GitLab Flex commitment.

## Monthly drawdown cycle

GitLab Flex operates on a monthly drawdown cycle based on calendar month.

- Beginning of the month
  - Seat count is set: GitLab sets your reserved seat count for the month, and charges for seats only at the end of the month.
  - Capabilities become active: GitLab enables all the capabilities you provisioned for the month.
  - Reserved credits become available: Your organization can start using your monthly credit pool.
  - Prior month's overage is billed: Any overage from the previous month is billed.
- During the month
  - Usage is tracked: GitLab meters your credit consumption in real time for usage-based products.
  - Reserved credits are consumed first: Your usage draws from your monthly reserved pool first. After you use up the pool, usage draws from your On-Demand spend.
- End of the month
  - Unused reserved credits expire: You lose any credits you did not use during the month, and they do not roll over. GitLab already debited the cost of these credits from your balance at the start of the month.
  - Reservation is debited: GitLab draws down your reserved credit pool and any reserved add-ons from your annual Flex balance at your discounted Flex rate. The drawdown reduces your reserved quantity at the discounted rate. It does not charge a separate dollar amount against your annual commitment.
  - Seats are charged at the monthly peak: GitLab counts the highest number of seats you used at any point during the month, and charges for that number. Seats above your reservation are charged at your per-seat rate and draw from your remaining Flex balance.
  - Overage is calculated: If your total monthly usage is more than your allocation, GitLab bills the extra amount separately at the beginning of the next month.

At the beginning of the next month, a new reservation debits and the drawdown cycle repeats with a new monthly allocation.

## Volume discounts

Tiered volume discounts are automatically applied based on your total Flex annual commitment amount.
The volume discount does not reduce your commitment value, the reserved credits are debited from your Flex balance at this discounted rate.
The higher your annual commitment, the lower your reserved per-credit rate.
The per-user effective price is a separate component and is determined independently of your volume discount tier.

## Buy GitLab Flex

GitLab Flex is available as a recurring annual or multi-year term, for full annual terms of 12 months.
To buy GitLab Flex, contact your GitLab account team or the [GitLab Sales team](https://about.gitlab.com/sales/).

Your annual commitment should account for:

- Base seat costs: Number of users × seat tier price (Premium or Ultimate) × 12 months.
- Expected credit usage: Estimated monthly consumption for credit-based capabilities × 12 months.
- Growth buffer: Additional capacity for mid-year expansion or new capability adoption.

Tiered volume discounts are available and automatically applied based on your total annual commitment size.

Multi-year contracts operate as separate annual pools.
This means that an unused balance in one year balance does not carry over to the following year.

After you sign your GitLab Flex agreement, you can start provisioning your initial allocation.

## Provisioning

You can provision and change your allocation in Customers Portal.
If provisioning is successful, GitLab sends an email confirmation with the allocation information to the subscription ("Sold to") contact.

- On GitLab.com, changes are synced to the namespace.
- On GitLab Self-Managed and GitLab Dedicated, you receive an [activation code](../administration/license.md) for your instance.

All future reservations are automatically synced to the namespace or instance used in the initial setup.

### Monthly reservation allocation

After you sign your GitLab Flex agreement, you can set your initial monthly reservation from the Flex dashboard.

The reservation management page displays:

- **Minimum required reservation**: The minimum monthly dollar amount fixed in your contract.
- **Maximum reservation**: The maximum monthly dollar amount available based on your remaining annual balance.
- **Seats**: The number of seats to reserve for the month.
- **Credits (DAP)**: The number of GitLab Credits (Duo Agent Platform) to reserve for the month.

### Adjust your allocation

You can adjust your Flex allocation month-to-month without contract amendments:

- Seat count: Increase or decrease the number of seats.
- Reserved credit pool: Increase or decrease your monthly use-it-or-lose-it credit reservation.
- Spend control: Adjust your monthly allocated spend for per-use capabilities.

Prerequisites:

- You must be a billing account manager.

To adjust your allocation for an upcoming billing period:

1. Sign in to [Customers Portal](https://customers.gitlab.com/).
1. Select **Flex dashboard**.
1. Select the upcoming billing period, which is marked as editable.
1. On the reservation management page, update the number of **Seats** and **Credits** (for Duo Agent Platform).
1. Select **Save reservation**.

After you save, a success message confirms the update. The Flex dashboard shows the new reserved amounts, which apply from the next billing period onward until you change them again.

You can update your reservation as many times as you want before the next billing period begins. Only the most recent saved value takes effect on the 1st of the month.

#### Credits reservation

If you set the number of **Credits** for GitLab Duo Agent Platform to `0`, no credits are reserved for that billing period. Any credit usage draws from your on-demand balance.

#### Allocation adjustment conditions

The following adjustment conditions apply:

- Changes must fit within your monthly starting commitment. This is your initial annual commitment divided by the number of months in your subscription.
- Due date for changes is the second-to-last day of the month. You must submit changes before 11:59 PM UTC on the second-to-last day of the current month to apply them to the next month.
  For example, you must submit changes by July 30th so that they apply to the month of August.
  After a month begins, that month's reservation is final and you can't reduce, reverse, or prorate it.
- Seat and reservation changes only take effect at month boundaries.
  You can't change your reservation mid-month.
- Offering is fixed. You can't change the offering selected in your contract.
- Minimum monthly reservation is fixed. You can't change the required monthly reservation fixed in your contract.
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
Based on your year-to-date consumption, overage patterns, capacity needs, and growth projections,
you can choose to increase or decrease your annual commitment.
The new volume discount tier is based on the renewed commitment amount.

## Flex Usage dashboard

The Flex Usage dashboard provides built-in tracking and reporting capabilities.

The dashboard displays:

- **Annual commitment and balance**: Total Flex commitment, year-to-date consumption, and remaining balance.
- **Monthly allocation**: Seat count, reserved credits, and per-use budget for the current month.
- **Credit consumption by capability**: Breakdown of credits used for each usage-based product.
- **Credit consumption by project**: Top projects by credit usage.
- **Credit consumption by offering**: Usage split between GitLab.com, GitLab Self-Managed, GitLab Dedicated, and offline environments.
- **Forecast vs. actual usage**: Projected annual consumption compared to actual pace.
- **Overage summary**: Month-to-date and year-to-date overage.

### Usage and spend controls

To help you control how much you spend against your commitment, you can set spend caps (at the subscription level) and receive budget alerts.

#### Spend caps

Per-capability caps limit how much a specific credit-based capability can consume, so one capability can't drain the shared pool.
When a capability hits its cap, usage stops while everything else keeps running.
The cap is per-product, not shared across the pool.

Use per-capability caps for non-critical or experimental features you want to contain.

You can set the following per-capability caps:

- Restricted: No overage past reservation, blocked at the reservation. The spend ceiling equals the reservation.
- Usage cap: Bounded overage past reservation. The spend ceiling is the reservation plus the capped amount.
- Unlimited: Unlimited overage past reservation. No spend ceiling.

Each capability has its own independent cap.
For example, you can cap GitLab Duo at $5,000 while leaving Artifact Registry unlimited.

#### Usage notifications

GitLab sends emails as usage approaches and crosses specific limits, running on the existing budget-guardrail framework.
Subscription billing contacts receive dollar-based notifications, and namespace administrators receive credit-based notifications.

GitLab sends usage notifications when:

- A product crosses 50%, 80%, or 100% of its monthly reservation. At 100% the product starts drawing per-use and is entering overage.
- A product first enters overage for the month, billing at the list rate against your annual commitment.
- A capped product crosses 50% or 80% of its cap (warning notification), or reaches 100% and is cut off (cut-off notification).

### View the Flex Usage dashboard

Prerequisites:

- You must be an administrator.

1. In the upper-right corner, select **Admin**.
1. In the left sidebar, select **Flex Usage**.

### Set a spend cap

To set a per-capability spend cap:

1. Sign in to [Customers Portal](https://customers.gitlab.com/).
1. Select **Flex dashboard**.
1. Select a month to display all capabilities.
1. In the row of the add-on you want to cap, from the **Spend Control** dropdown list, select a cap type.
   If you enter a value for the cap, it is converted to a dollar figure at that product's rate.
1. Review the reservation summary to confirm the caps are reflected in your add-ons subtotal and total.
1. Select **Save**.
