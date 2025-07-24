---
stage: Fulfillment
group: Subscription Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Seat usage, compute minutes, storage limits, renewal info.
title: GitLab.com subscription
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com

{{< /details >}}

{{< alert type="note" >}}

The GitLab SaaS subscription is being renamed to GitLab.com. During this transition, you might see references to GitLab SaaS and GitLab.com in the UI and documentation.

{{< /alert >}}

GitLab.com is the GitLab multi-tenant software-as-a-service (SaaS) offering.
You don't need to install anything to use GitLab.com, you only need to
[sign up](https://gitlab.com/users/sign_up). When you sign up, you choose:

- [A subscription](https://about.gitlab.com/pricing/).
- [The number of seats you want](../manage_users_and_seats.md#gitlabcom-billing-and-usage).

The subscription determines which features are available for your private projects. Organizations with public open source projects can actively apply to our [GitLab for Open Source Program](https://about.gitlab.com/solutions/open-source/join/).

Qualifying open source projects also get 50,000 compute minutes and free access to the **Ultimate** tier
through the [GitLab for Open Source program](https://about.gitlab.com/solutions/open-source/).

## Search seat usage

To search seat usage:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > Usage Quotas**.
1. On the **Seats tab**, enter a string in the search field. A minimum of 3 characters are required.

The search returns users whose first name, last name, or username contain the search string.

For example:

| First name | Search string | Match ? |
|:-----------|:--------------|:--------|
| Amir       | `ami`         | Yes     |
| Amir       | `amr`         | No      |

## Compute minutes

[Compute minutes](../../ci/pipelines/compute_minutes.md) is the resource consumed when running
[CI/CD pipelines](../../ci/_index.md) on GitLab instance runners. If you run out of compute minutes,
you can [purchase additional compute minutes](compute_minutes.md).

## Purchase more storage

{{< details >}}

- Tier: Free

{{< /details >}}

{{< alert type="note" >}}

To exceed the free tier 10 GiB limit on your Free GitLab.com namespace, you can purchase more storage for your personal or group namespace.

{{< /alert >}}

Prerequisites:

- You must have the Owner role.

{{< alert type="note" >}}

Storage subscriptions **renew automatically each year**.
You can [disable automatic subscription renewal](../manage_subscription.md#turn-on-or-turn-off-automatic-subscription-renewal).

{{< /alert >}}

### For your personal namespace

1. Sign in to GitLab.com.
1. From either your personal homepage or the group's page, go to **Settings > Usage Quotas**.
1. Select the **Storage** tab.
1. For each read-only project, total by how much its **Usage** exceeds the free quota and purchased
   storage. You must purchase the storage increment that exceeds this total.
1. Select **Buy storage**. You are taken to the Customers Portal.
1. In the **Subscription details** section, select the name of the user from the dropdown list.
1. Enter the desired quantity of storage packs.
1. In the **Customer information** section, verify your address.
1. In the **Billing information** section, select the payment method from the dropdown list.
1. Select the **Privacy Statement** and **Terms of Service** checkboxes.
1. Select **Buy storage**.

The **Purchased storage available** total is incremented by the amount purchased. The read-only
state for all projects is removed, and their excess usage is deducted from the additional storage.

### For your group namespace

If you're using GitLab.com, you can purchase additional storage so your
pipelines aren't blocked after you have used all your storage from your
main quota. You can find pricing for additional storage on the
[GitLab Pricing page](https://about.gitlab.com/pricing/#storage).

To purchase additional storage for your group on GitLab.com:

1. Sign in to GitLab.com.
1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > Usage Quotas**.
1. Select the **Storage** tab.
1. Select **Buy storage**. You are taken to the Customers Portal.
1. In the **Subscription details** section, enter the desired quantity of storage packs.
1. In the **Customer information** section, verify your address.
1. In the **Billing information** section, select a payment method from the dropdown list.
1. Select the **Privacy Statement** and **Terms of Service** checkboxes.
1. Select **Buy storage**.

After your payment is processed, the extra storage is available for your group namespace.

To confirm the available storage, follow the first three steps listed previously.

The **Purchased storage available** total is incremented by the amount purchased. All locked
projects are unlocked and their excess usage is deducted from the additional storage.
