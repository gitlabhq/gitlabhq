---
stage: Fulfillment
group: Seat Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Manage users and seats associated with your GitLab subscription.
title: Manage users and seats
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

## Billable users

Billable users count toward the number of subscription seats purchased in your subscription.
The number of billable users changes when you block, deactivate, or add
users to your instance or group during your current subscription period.

Seat usage is reviewed [quarterly or annually](quarterly_reconciliation.md).
On GitLab Self-Managed, the amount of **Billable users** is reported once a day in the **Admin** area.

On GitLab.com, subscription features apply only within the top-level group the subscription applies to. If
a user views or selects a different top-level group (one they have created themselves, for example)
and that group does not have a paid subscription, the user does not see any of the paid features.

A user can belong to two different top-level groups with different subscriptions.
In this case, the user sees only the features available to that subscription.

## Criteria for non-billable users

A user is not counted as a billable user if:

- They are pending approval.
- They are [deactivated](../administration/moderate_users.md#deactivate-a-user),
  [banned](../user/group/moderate_users.md#ban-a-user),
  or [blocked](../administration/moderate_users.md#block-a-user).
- They are not a member of any projects or groups (Ultimate subscriptions only).
- They have only the [Guest role](#free-guest-users) (Ultimate subscriptions only).
- They have only the [Minimal Access role](../user/permissions.md#users-with-minimal-access) for any GitLab.com subscriptions.
- The account is a GitLab-created service account:
  - [Ghost User](../user/profile/account/delete_account.md#associated-records).
  - Bots:
    - [Support Bot](../user/project/service_desk/configure.md#support-bot-user).
    - [Bot users for projects](../user/project/settings/project_access_tokens.md#bot-users-for-projects).
    - [Bot users for groups](../user/group/settings/group_access_tokens.md#bot-users-for-groups).
    - Other [internal users](../administration/internal_users.md).

## Free Guest users

{{< details >}}

- Tier: Ultimate

{{< /details >}}

In the **Ultimate** tier, users who are assigned the Guest role do not consume a seat.
The user must not be assigned any other role, anywhere in the instance for GitLab Self-Managed or in the namespace for GitLab.com.

- If your project is:
  - Private or internal, a user with the Guest role has [a set of permissions](../user/permissions.md#project-members-permissions).
  - Public, all users, including those with the Guest role, can access your project.
- For GitLab.com, if a user with the Guest role creates a project in their personal namespace, the user does not consume a seat.
The project is under the user's personal namespace and does not relate to the group with the Ultimate subscription.
- On GitLab Self-Managed, a user's highest assigned role is updated asynchronously and may take some time to update.

{{< alert type="note" >}}

On GitLab Self-Managed, if a user creates a project, they are assigned the Maintainer or Owner role.
To prevent a user from creating projects, as an administrator, you can mark the user
as [external](../administration/external_users.md).

{{< /alert >}}

## Buy more seats

{{< details >}}

- Offering: GitLab.com, GitLab Self-Managed

{{< /details >}}

Your subscription cost is based on the maximum number of seats you use during the billing period.

If [restricted access](../user/group/manage.md#turn-on-restricted-access) is:

- On, when there are no seats left in your subscription you must purchase more seats for groups to add new billable users.
- Off, when there are no seats left in your subscription groups can continue to add billable users.
  GitLab [bills you for the overage](quarterly_reconciliation.md).

You cannot buy seats for your subscription if either:

- You purchased your subscription through an [authorized reseller](customers_portal.md#customers-that-purchased-through-a-reseller) (including GCP and AWS marketplaces). Contact the reseller to add more seats.
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

You receive the payment receipt by email.
You can also access the receipt in the Customers Portal under [**Invoices**](https://customers.gitlab.com/invoices).
