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

Billable users are users with access to a namespace in a subscription, such as direct [members](../user/project/members/_index.md#membership-types),
inherited members, and invited users, with one of the following roles:

- Guest (billable on Premium, non-billable on Free and Ultimate)
- Planner
- Reporter
- Developer
- Maintainer
- Owner

Billable users count toward the number of seats purchased in your subscription.
The number of billable users changes when you block, deactivate, or add
users to your instance or group during your current subscription period.
If a user is in multiple groups or projects that belong to the same top-level group that holds the subscription, they are counted only once.

Seat usage is reviewed [quarterly or annually](quarterly_reconciliation.md).
On GitLab Self-Managed, the amount of **Billable users** is reported once a day in the **Admin** area.

On GitLab.com, subscription features apply only within the top-level group the subscription applies to. If
a user views or selects a different top-level group (one they have created themselves, for example)
and that group does not have a paid subscription, the user does not see any of the paid features.

A user can belong to two different top-level groups with different subscriptions.
In this case, the user sees only the features available to that subscription.

To prevent unexpectedly adding new billable users, which may result in overage fees, you should:

- [Prevent inviting groups outside the group hierarchy](../user/project/members/sharing_projects_groups.md#prevent-inviting-groups-outside-the-group-hierarchy).
- [Turn on restricted access](../user/group/manage.md#turn-on-restricted-access).

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

## Users over subscription limit

When the number of billable users in your instance or top-level group exceeds the number of seats you've purchased,
you have users over subscription (or seats owed).

This can happen, for example, when new users are added to your instance or group,
or existing users are promoted to billable roles.

The number of users over subscription is calculated as:
maximum users during billing period - purchased seats in your subscription.

For example, you purchase a subscription for 10 seats, and during the billing period the number of users varies as follows:

| Event                                             | Billable users | Maximum users |
|:--------------------------------------------------|:----------------|:--------------|
| Ten users occupy all 10 seats.                    | 10              | 10            |
| Two new users join.                               | 12              | 12            |
| Three users leave and their accounts are blocked. | 9               | 12            |
| Four new users join.                              | 13              | 13            |

In this case, you have 3 users over subscription (13 maximum users - 10 purchased seats).

When you exceed your subscription limit, you must pay for the additional users
[before or at the time of renewal](quarterly_reconciliation.md).
The cost is based on the maximum number of users during the billing period, not the current number of users.

On GitLab Self-Managed, for trial licenses the users over subscription value is always zero.

To avoid unexpected overage charges, you can:

- [Turn on restricted access](../user/group/manage.md#turn-on-restricted-access) to prevent adding users when no seats remain.
- [Require administrator approval for new sign-ups](../administration/settings/sign_up_restrictions.md#require-administrator-approval-for-new-sign-ups).
- Buy more seats proactively when approaching your limit.

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

- You purchased your subscription through an [authorized reseller](billing_account.md#subscription-purchased-through-a-reseller) (including GCP and AWS marketplaces). Contact the reseller to add more seats.
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

## Reduce seats

You can reduce seats only during subscription renewal.
If you want to reduce the number of seats in your subscription, you can [renew for fewer seats](manage_subscription.md#renew-for-fewer-seats).

## Self-Managed billing and usage

{{< details >}}

- Offering: GitLab Self-Managed

{{< /details >}}

A GitLab Self-Managed subscription uses a hybrid model. You pay for a subscription
according to the maximum number of users enabled during the
subscription period.

For instances that are not offline or on a closed network, the maximum number of
simultaneous users in the GitLab Self-Managed instance is checked each quarter.

If an instance is unable to generate a quarterly usage report, the existing
true up model is used. Prorated charges are not
possible without a quarterly usage report.

The number of users in subscription represents the number of users included in your current license,
based on what you've paid for.
This number remains the same throughout your subscription period unless you purchase more seats.

The number of maximum users reflects the highest number of billable users on your system for the current license period.

You can view and export your [license usage](../administration/license_usage.md).

### View users

View the lists of users in your instance:

1. On the left sidebar, at the bottom, select **Admin**. If you've [turned on the new navigation](../user/interface_redesign.md#turn-new-navigation-on-or-off), in the upper-right corner, select your avatar and then select **Admin**.
1. Select **Users**.

Select a user to view their account information.

#### Check daily and historical billable users

Prerequisites:

- You must be an administrator.

You can get a list of daily and historical billable users in your GitLab instance:

1. [Start a Rails console session](../administration/operations/rails_console.md#starting-a-rails-console-session).
1. Count the number of users in the instance:

   ```ruby
   User.billable.count
   ```

1. Get the historical maximum number of users on the instance from the past year:

   ```ruby
   ::HistoricalData.max_historical_user_count(from: 1.year.ago.beginning_of_day, to: Time.current.end_of_day)
   ```

#### Update daily and historical billable users

Prerequisites:

- You must be an administrator.

You can trigger a manual update of the daily and historical billable users in your GitLab instance.

1. [Start a Rails console session](../administration/operations/rails_console.md#starting-a-rails-console-session).
1. Force an update of the daily billable users:

   ```ruby
   identifier = Analytics::UsageTrends::Measurement.identifiers[:billable_users]
   ::Analytics::UsageTrends::CounterJobWorker.new.perform(identifier, User.minimum(:id), User.maximum(:id), Time.zone.now)
   ```

1. Force an update of the historical max billable users:

   ```ruby
   ::HistoricalDataWorker.new.perform
   ```

### Manage users and subscription seats

Managing the number of users against the number of subscription seats can be difficult:

- If [LDAP is integrated with GitLab](../administration/auth/ldap/_index.md), anyone
  in the configured domain can sign up for a GitLab account. This can result in
  an unexpected bill at time of renewal.
- If sign-up is turned on in your instance, anyone who can access the instance can
  sign up for an account.

GitLab has several features to help you manage the number of users. You can:

- [Require administrator approval for new sign ups](../administration/settings/sign_up_restrictions.md#require-administrator-approval-for-new-sign-ups).
- Automatically block new users, either through
  [LDAP](../administration/auth/ldap/_index.md#basic-configuration-settings) or
  [OmniAuth](../integration/omniauth.md#configure-common-settings).
- [Limit the number of billable users](../administration/settings/sign_up_restrictions.md#user-cap)
  who can sign up or be added to a subscription without administrator approval.
- [Disable new sign-ups](../administration/settings/sign_up_restrictions.md),
  and instead manage new users manually.
- View a breakdown of users by role in the
  [Users statistics](../administration/admin_area.md#users-statistics) page.
- [Turn on administrator approval for role promotions](../administration/settings/sign_up_restrictions.md#turn-on-administrator-approval-for-role-promotions).
- [Prevent users with the Guest role from creating projects and groups](../administration/settings/account_and_limit_settings.md#prevent-non-members-from-creating-projects-and-groups).

To increase the number of users covered by your license, [buy more seats](#buy-more-seats)
during the subscription period. The cost of seats added during the subscription
period is prorated from the date of purchase through to the end of the subscription
period. You can continue to add users even if you reach the number of users in
license count. GitLab [bills you for the overage](quarterly_reconciliation.md).

If your subscription was activated with an activation code, the additional seats are reflected in
your instance immediately. If you're using a license file, you receive an updated file.
To add the seats, [add the license file](../administration/license_file.md)
to your instance.

## GitLab.com billing and usage

{{< details >}}

- Offering: GitLab.com

{{< /details >}}

A GitLab.com subscription uses a concurrent (seat) model.
You choose a number of seats for users who can use the subscription at the same time,
and pay for a subscription according to the maximum number of users assigned to the top-level group,
its subgroups and projects during the billing period.

You can add and remove users during the subscription period without incurring additional charges,
as long as the total number of users at any given time doesn't exceed the number of seats in the subscription.
If you add more users and exceed the number of purchased seats, you incur an overage,
which will be included in your next [invoice](quarterly_reconciliation.md).

### Seat usage alerts

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/348481) in GitLab 15.2 [with a flag](../administration/feature_flags/_index.md) named `seat_flag_alerts`.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/362041) in GitLab 15.4. Feature flag `seat_flag_alerts` removed.

{{< /history >}}

If you have the Owner role for a top-level group that is linked to a subscription enrolled in
[quarterly subscription reconciliations](quarterly_reconciliation.md),
you receive alerts about the seat usage in the subscription.

The alert displays on group, subgroup, and project pages.
After you dismiss the alert, it doesn't display again until another seat is used.

The alert displays at the following intervals:

| Seats in subscription | Alert               |
|-----------------------|---------------------|
| 0-15                  | One seat remains.   |
| 16-25                 | Two seats remain.   |
| 26-99                 | 10% of seats remain.|
| 100-999               | 8% of seats remain. |
| 1000+                 | 5% of seats remain. |

### View seat usage

To view a list of seats being used:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings** > **Usage quotas**.
1. Select the **Seats** tab.

For each user, a list shows groups and projects where the user is a direct member.

- **Group invite** indicates the user is a member of a [group invited to a group](../user/project/members/sharing_projects_groups.md#invite-a-group-to-a-group).
- **Project invite** indicates the user is a member of a [group invited to a project](../user/project/members/sharing_projects_groups.md#invite-a-group-to-a-project).

The data in seat usage listing, **Seats in use**, and **Seats in subscription** are updated live.
The counts for **Max seats used** and **Seats owed** are updated once per day.

#### View billing information

To view your subscription information and a summary of seat counts:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings** > **Billing**.

- The usage statistics are updated once per day, which may cause a difference between the information
  in the **Usage quotas** page and the **Billing page**.
- The **Last login** field is updated when a user signs in after they have signed out. If there is an active session
  when a user re-authenticates (for example, after a 24 hour SAML session timeout), this field is not updated.

### Search users' seat usage

You can view the users that use seats on your subscription.
To search for a user's seat usage:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings** > **Usage quotas**.
1. On the **Seats** tab, in the search field, enter the user's name or username.
   The search string must have minimum three characters.

The search returns a list of users whose first name, last name, or username match the search string.

For example, for a user with the first name Amir,
the search string `ami` results in a match, but `amr` does not.

### Export seat usage data

To export seat usage data as a CSV file:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings** > **Usage quotas**.
1. In the **Seats** tab, select **Export list**.

### Export seat usage history

Prerequisites:

- You must have the Owner role for the group.

To export seat usage history as a CSV file:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings** > **Usage quotas**.
1. In the **Seats** tab, select **Export seat usage history**.

The generated list contains all seats being used,
and is not affected by the current search.

### Remove users from subscription

To remove a billable user from your GitLab.com subscription:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings** > **Billing**.
1. In the **Seats currently in use** section, select **See usage**.
1. In the row for the user you want to remove, on the right side, select **Remove user**.
1. Re-type the username and select **Remove user**.

If you add a member to a group by using the [share a group with another group](../user/project/members/sharing_projects_groups.md#invite-a-group-to-a-group) feature, you can't remove the member by using this method. Instead, you can either:

- [Remove the member from the shared group](../user/group/_index.md#remove-a-member-from-the-group).
- [Remove the invited group](../user/project/members/sharing_projects_groups.md#remove-an-invited-group).
