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
- [The number of seats you want](#how-seat-usage-is-determined).

The subscription determines which features are available for your private projects. Organizations with public open source projects can actively apply to our [GitLab for Open Source Program](https://about.gitlab.com/solutions/open-source/join/).

Qualifying open source projects also get 50,000 compute minutes and free access to the **Ultimate** tier
through the [GitLab for Open Source program](https://about.gitlab.com/solutions/open-source/).

## Add or change subscription contacts

Contacts can renew a subscription, cancel a subscription, or transfer the subscription to a different namespace.

You can [change profile owner information](../customers_portal.md#change-profile-owner-information)
and [add another billing account manager](../customers_portal.md#add-a-billing-account-manager).

## How seat usage is determined

A GitLab.com subscription uses a concurrent (_seat_) model.
You pay for a subscription according to the maximum number of users assigned to the top-level group,
its subgroups and projects during the billing period.
You can add and remove users during the subscription period without incurring additional charges,
as long as the total users at any given time doesn't exceed the subscription count.
If the total users exceeds your subscription count, you will incur an overage,
which must be paid at your next [reconciliation](../quarterly_reconciliation.md).

A top-level group can be [changed](../../user/group/manage.md#change-a-groups-path) like any other group.

### Billable users

Billable users count toward the number of subscription seats purchased in your subscription.

A user is not counted as a billable user if:

- They are pending approval.
- They have only the [Guest role on an Ultimate subscription](#free-guest-users).
- They have only the [Minimal Access role](../../user/permissions.md#users-with-minimal-access) for any GitLab.com subscriptions.
- They are a [banned member](../../user/group/moderate_users.md#ban-a-user).
- They are a [blocked user](../../administration/moderate_users.md#block-a-user).
- The account is a GitLab-created service account:
  - [Ghost User](../../user/profile/account/delete_account.md#associated-records).
  - Bots:
    - [Support Bot](../../user/project/service_desk/configure.md#support-bot-user).
    - [Bot users for projects](../../user/project/settings/project_access_tokens.md#bot-users-for-projects).
    - [Bot users for groups](../../user/group/settings/group_access_tokens.md#bot-users-for-groups).

Seat usage is reviewed [quarterly or annually](../quarterly_reconciliation.md).

If a user views or selects a different top-level group (one they have created themselves, for example)
and that group does not have a paid subscription, the user does not see any of the paid features.

A user can belong to two different top-level groups with different subscriptions.
In this case, the user sees only the features available to that subscription.

### Free Guest users

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

In the **Ultimate** tier, users who are assigned the Guest role do not consume a seat.
The user must not be assigned any other role, anywhere in the instance or in the namespace for GitLab.com.

- If your project is:
  - Private or internal, a user with the Guest role has [a set of permissions](../../user/permissions.md#project-members-permissions).
  - Public, all users, including those with the Guest role, can access your project.
- For GitLab.com, if a user with the Guest role creates a project in their personal namespace, the user does not consume a seat.
The project is under the user's personal namespace and does not relate to the group with the Ultimate subscription.

### Seats owed

If the number of billable users exceeds the number of **seats in subscription**, known
as the number of **seats owed**, you must pay for the excess number of users.

For example, if you purchase a subscription for 10 users:

| Event                                              | Billable members | Maximum users |
|:---------------------------------------------------|:-----------------|:--------------|
| Ten users occupy all 10 seats.                     | 10               | 10            |
| Two new users join.                                | 12               | 12            |
| Three users leave and their accounts are removed.  | 9                | 12            |

Seats owed = 12 - 10 (Maximum users - users in subscription)

To prevent charges from seats owed, you can
[turn on restricted access](../../user/group/manage.md#turn-on-restricted-access).
This setting restricts groups from adding new billable users when there are no seats left in the subscription.

### Seat usage alerts

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/348481) in GitLab 15.2 [with a flag](../../administration/feature_flags/_index.md) named `seat_flag_alerts`.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/362041) in GitLab 15.4. Feature flag `seat_flag_alerts` removed.

{{< /history >}}

If you have the Owner role for the top-level group, an alert notifies you
of your total seat usage.

The alert displays on group, subgroup, and project
pages, and only for top-level groups linked to subscriptions enrolled
in [quarterly subscription reconciliations](../quarterly_reconciliation.md).
After you dismiss the alert, it doesn't display until another seat is used.

The alert displays based on the following seat usage. You cannot configure the
amounts at which the alert displays.

| Seats in subscription | Alert displays when |
|-----------------------|---------------------|
| 0-15                  | One seat remains.   |
| 16-25                 | Two seats remain.   |
| 26-99                 | 10% of seats remain.|
| 100-999               | 8% of seats remain. |
| 1000+                 | 5% of seats remain. |

## View seat usage

To view a list of seats being used:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > Usage Quotas**.
1. Select the **Seats** tab.

For each user, a list shows groups and projects where the user is a direct member.

- **Group invite** indicates the user is a member of a [group invited to a group](../../user/project/members/sharing_projects_groups.md#invite-a-group-to-a-group).
- **Project invite** indicates the user is a member of a [group invited to a project](../../user/project/members/sharing_projects_groups.md#invite-a-group-to-a-project).

The data in seat usage listing, **Seats in use**, and **Seats in subscription** are updated live.
The counts for **Max seats used** and **Seats owed** are updated once per day.

### View billing information

To view your subscription information and a summary of seat counts:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > Billing**.

- The usage statistics are updated once per day, which may cause a difference between the information
  in the **Usage Quotas** page and the **Billing page**.
- The **Last login** field is updated when a user signs in after they have signed out. If there is an active session
  when a user re-authenticates (for example, after a 24 hour SAML session timeout), this field is not updated.

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

## Export seat usage

To export seat usage data as a CSV file:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > Usage Quotas**.
1. In the **Seats** tab, select **Export list**.

## Export seat usage history

Prerequisites:

- You must have the Owner role for the group.

To export seat usage history as a CSV file:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > Usage Quotas**.
1. In the **Seats** tab, select **Export seat usage history**.

The generated list contains all seats being used,
and is not affected by the current search.

## Buy seats for a subscription

Your subscription cost is based on the maximum number of seats you use during the billing period.

- If [restricted access](../../user/group/manage.md#turn-on-restricted-access)
  is turned on, when there are no seats left in your subscription you must purchase more seats for groups to add new billable users.
- If restricted access is turned off, when there are no seats left in your subscription groups can continue to add billable
  users. GitLab [bills you for the overage](../quarterly_reconciliation.md).

You cannot buy seats for your subscription if either:

- You purchased your subscription through an [authorized reseller](../customers_portal.md#customers-that-purchased-through-a-reseller) (including GCP and AWS marketplaces). Contact the reseller to add more seats.
- You have a multi-year subscription. Contact the [sales team](https://customers.gitlab.com/contact_us) to add more seats.

To buy seats for a subscription:

1. Sign in to the [Customers Portal](https://customers.gitlab.com/).
1. Go to the **Subscriptions & purchases** page.
1. Select **Add seats** on the relevant subscription card.
1. Enter the number of additional users.
1. Review the **Purchase summary** section. The system lists the total price for all users on the system and a credit for what you've already paid. You are only charged for the net change.
1. Enter your payment information.
1. Check the **I accept the Privacy Statement and Terms of Service** checkbox.
1. Select **Purchase seats**.

You receive the payment receipt by email. You can also access the receipt in the Customers Portal under [**Invoices**](https://customers.gitlab.com/invoices).

## Remove users from subscription

To remove a billable user from your GitLab.com subscription:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > Billing**.
1. In the **Seats currently in use** section, select **See usage**.
1. In the row for the user you want to remove, on the right side, select **Remove user**.
1. Re-type the username and select **Remove user**.

If you add a member to a group by using the [share a group with another group](../../user/project/members/sharing_projects_groups.md#invite-a-group-to-a-group) feature, you can't remove the member by using this method. Instead, you can either:

- [Remove the member from the shared group](../../user/group/_index.md#remove-a-member-from-the-group).
- [Remove the invited group](../../user/project/members/sharing_projects_groups.md#remove-an-invited-group).

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
