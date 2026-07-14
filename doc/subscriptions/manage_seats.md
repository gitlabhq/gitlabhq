---
stage: Fulfillment
group: Seat Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Manage users and seats associated with your GitLab subscription.
title: Manage seats
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Seat management is the process of controlling and monitoring which users occupy seats in your subscription.
Effective seat management helps you control costs, prevent unexpected overage charges, and ensure your team members have the access they need.

## Billable users

Billable users are users who occupy seats in a subscription and count toward the number of seats purchased in your subscription.

The following users count as billable:

- Users with access to a namespace or top-level group in a subscription, such as direct [members](../user/project/members/_index.md#membership-types), inherited members, and invited users with one of these roles:
  - Guest (billable on Premium, non-billable on Free and Ultimate)
  - Planner
  - Reporter
  - Security Manager
  - Developer
  - Maintainer
  - Owner
  - [Custom role](../user/custom_roles/_index.md), except custom Guest member role with only the `read_code` permission
- [Auditor users](../administration/auditor_users.md)
- Administrators (on GitLab Self-Managed on the Premium and Ultimate tiers)
- Users without namespace access (on GitLab Self-Managed on the Premium tier)

The number of billable users changes when you block, deactivate, or add users to your instance or group during your current subscription period.
If a user is in multiple groups or projects that belong to the same top-level group that holds the subscription, they are counted only once.

Seat usage is reviewed [quarterly or annually](quarterly_reconciliation.md).

To prevent overage fees from unintended user additions, you should:

- [Prevent inviting groups outside the group hierarchy](../user/project/members/sharing_projects_groups.md#prevent-inviting-groups-outside-the-group-hierarchy).
- Turn on restricted access.

## Criteria for non-billable users

A user is not counted as a billable user if:

- They are pending approval.
- They are [deactivated](../administration/moderate_users.md#deactivate-a-user),
  [banned](../user/group/moderate_users.md#ban-a-user),
  or [blocked](../administration/moderate_users.md#block-a-user).
- They are not a member of any projects or groups (Ultimate subscriptions only).
- They have only the Guest role (Ultimate subscriptions only).
- They have only the [Minimal Access role](../user/permissions.md#users-with-minimal-access).
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
before or at the time of renewal.
The cost is based on the maximum number of users during the billing period, not the current number of users.

On GitLab Self-Managed, for trial licenses the users over subscription value is always zero.

To avoid unexpected overage charges, you can:

- Turn on restricted access to prevent adding users when no seats remain.
- [Require administrator approval for new user accounts](../administration/settings/sign_up_restrictions.md#require-administrator-approval-for-new-user-accounts).
- Buy more seats proactively when approaching your limit.

## Free Guest users

{{< details >}}

- Tier: Ultimate

{{< /details >}}

In the **Ultimate** tier, users who are assigned the Guest role do not consume a seat.
The user must not be assigned any other role, anywhere in the instance for GitLab Self-Managed or in the namespace for GitLab.com.

On GitLab Self-Managed in the **Premium** tier, if a Guest user has a higher role in any project or group (including their personal namespace),
when you upgrade to the **Ultimate** tier that higher role takes precedence and they will consume a seat.
To ensure that Guest users on GitLab Self-Managed Ultimate will not consume a seat,
confirm that they have no other role assignments in the instance or namespace before upgrading.

- If your project is:
  - Private or internal, a user with the Guest role has [a set of permissions](../user/permissions.md#project-permissions).
  - Public, all users, including those with the Guest role, can access your project.
- For GitLab.com, if a user with the Guest role creates a project in their personal namespace, the user does not consume a seat.
  The project is under the user's personal namespace and does not relate to the group with the Ultimate subscription.
- On GitLab Self-Managed, a user's highest assigned role is updated asynchronously and may take some time to update.

> [!note]
> On GitLab Self-Managed, if a user creates a project, they are assigned the Maintainer or Owner role.
> To prevent a user from creating projects, as an administrator, you can mark the user
> as [external](../administration/external_users.md).

## Seat controls

Seat controls help you manage how users are added to your subscription and prevent unexpected overage fees.
Seat controls apply to the instance on GitLab Self-Managed, and to the top-level group on GitLab.com.

### User cap

{{< history >}}

- [Enabled on GitLab.com](https://gitlab.com/groups/gitlab-org/-/epics/9263) in GitLab 16.3.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/421693) in GitLab 17.1. Feature flag `saas_user_caps` removed.

{{< /history >}}

The user cap is the maximum number of billable users who can be added to a top-level group on GitLab.com, or create accounts on GitLab Self-Managed.
After the user cap is reached, a group Owner or administrator must approve the users to be added to a top-level group or create accounts.
After the users have been approved, they can access the group or instance.
If a group Owner or an administrator increases or removes the user cap, users pending approval are automatically approved.

You can set a user cap [for a top-level group](../user/group/manage.md#set-a-user-cap-for-a-group)
and [for an instance](../administration/settings/sign_up_restrictions.md#set-a-user-cap).

> [!note]
> On GitLab.com, the user cap cannot be enabled if any group, subgroup, or project within the top-level group is shared outside of that namespace hierarchy.
> While the user cap is enabled, [inviting groups outside the group hierarchy](../user/project/members/sharing_projects_groups.md#prevent-inviting-groups-outside-the-group-hierarchy) is prevented automatically and cannot be turned off. Inviting groups within the group and its subgroups is unaffected.

The number of billable users is updated once a day.
The user cap might take effect only after it has already been exceeded.
If the cap is set to a value below the current number of billable users (for example, `1`), the cap is enabled immediately.

> [!note]
> On GitLab Self-Managed, for instances that use LDAP or OmniAuth,
> when administrator approval for new user accounts is enabled or disabled,
> downtime might occur due to changes in the Rails configuration.
> You can set a user cap to enforce approvals for new users.

On GitLab.com Ultimate, you cannot add Guest users to a group when billable users exceed the user cap.
For example, you set the user cap to five when you have three Developers and two Guests. After you add two more Developers,
you cannot add any more users, even if they are Guest users who don't consume billable seats.
For more information, see [issue 441504](https://gitlab.com/gitlab-org/gitlab/-/issues/441504).

### Restricted access

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/442718) in GitLab 17.5.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/523468) in GitLab 18.0.
- Group sharing settings [changed](https://gitlab.com/gitlab-org/gitlab/-/issues/488451) in GitLab 18.7.
- Automatic restricted access for GitLab Self-Managed [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/240092) in GitLab 19.1 [with a feature flag](../administration/feature_flags/_index.md) named `auto_enable_restricted_access_on_self_managed`. Enabled by default.

{{< /history >}}

Restricted access blocks new billable users from being added when no licensed seats remain in your subscription.
Enabling restricted access on a group or instance that is already over its seat limit does not change the role of, block, or remove any existing members;
it prevents new billable additions while leaving current members untouched.
Users who don't need access to projects or groups, such as those authenticating through GitLab as an OIDC provider, can be assigned the non-billable Minimal Access role to not be blocked by seat limits.

You can set restricted access [for a top-level group](../user/group/manage.md#turn-on-restricted-access)
and [for an instance](../administration/settings/sign_up_restrictions.md#turn-on-restricted-access).

Restricted access is incompatible with external group sharing. When you turn on restricted access on GitLab .com, the setting to [prevent inviting groups outside the group hierarchy](../user/project/members/sharing_projects_groups.md#prevent-inviting-groups-outside-the-group-hierarchy) is automatically turned on.
This setting prevents overage fees caused by unintended billable users.

You can still independently configure [project sharing for the group and its subgroups](../user/project/members/sharing_projects_groups.md#prevent-a-project-from-being-shared-with-groups) as needed.

Restricted access and user cap cannot be used together.
Enabling restricted access disables user cap.

On GitLab Self-Managed, GitLab turns on restricted access automatically when your subscription does not allow overages.
You cannot turn off restricted access when your subscription does not allow overages.

#### Provisioning behavior with SAML, SCIM, and LDAP

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/206932) in GitLab 18.6 [with a feature flag](../administration/feature_flags/_index.md) named `bso_minimal_access_fallback`. Disabled by default.
- [Enabled by default](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/225777) in GitLab 18.10.

{{< /history >}}

When restricted access is enabled and no subscription seats are available, users provisioned through SAML, SCIM, or LDAP are assigned the Minimal Access role instead of their configured access level.
This behavior ensures that synchronization can continue without consuming billable seats on GitLab.com and Self-Managed Ultimate.

Users with the Minimal Access role can authenticate and access the group, but have [limited permissions](../user/permissions.md#users-with-minimal-access).
When seats become available, they can be promoted to their intended access level.
Existing users with billable roles are not affected by this behavior.

You can view seat usage and manage users with Minimal Access.

#### Known issues

When you turn on restricted access, the following known issues might occur and result in overages:

- The number of seats can still be exceeded if:
  - You use SAML, SCIM, or LDAP to add new members, and have exceeded the number of seats in the subscription. When the Minimal Access fallback feature is enabled, users are assigned Minimal Access instead of being blocked.
  - Multiple users with the Owner role or administrator access add members simultaneously.
- If you renew your subscription through the GitLab Sales Team for fewer users than your current
  subscription, you will incur an overage fee. To avoid this fee, remove additional users before your
  renewal starts. For example, if you have 20 users and renew your subscription for 15 users,
  you will be charged overages for the five additional users.

Additionally, restricted access might block the standard non-overage flows:

- Service bots that are updated or added to a billable role are incorrectly blocked.
- Inviting or updating existing billable users through email is blocked unexpectedly.

#### Dormant user reactivation

When restricted access is active and no licensed seats are available,
dormant users (including [enterprise users](../user/enterprise_user/_index.md))
who attempt to sign back in are set to pending approval instead of being reactivated.
Their existing group and project memberships are preserved.
Non-enterprise dormant members have their group membership removed instead of being deactivated.
When they rejoin through SAML, SCIM, or LDAP sync, provisioning behavior applies
and they receive the Minimal Access role if no seats are available.

A group Owner or an administrator can approve the users when seats become available.

Users with only the Minimal Access role are reactivated directly, because they do not consume a billable seat.

You can [automatically remove dormant members](../user/group/moderate_users.md#automatically-remove-dormant-members).

#### Pending invitation acceptance

After you turn on restricted access, it governs whether a pending invitation can proceed:

- On GitLab.com, when no subscription seats remain, a user cannot accept a pending invitation
  that grants a billable role. The invitation remains pending until a group Owner makes a seat
  available, either by purchasing more seats or removing billable members.
- On GitLab Self-Managed:
  - On the Ultimate tier, the same behavior applies. The invitation remains pending
    until an administrator makes a seat available, either by purchasing more seats or removing
    billable members.
  - On the Premium tier, restricted access enforces the seat limit when the account is created,
    rather than when the invitation is accepted. GitLab notifies the user when they register
    that their account could not be created and they should contact a GitLab administrator.

### Changing from user cap to restricted access

On GitLab.com, when you change from user cap to restricted access, all pending members (both members awaiting approval and invited members) are automatically removed.
To ensure users are approved as members, you must approve or remove pending members before enabling restricted access.

On GitLab Self-Managed, the user cap holds new user accounts pending admin approval, instead of blocking group or project members as on GitLab.com.
When you change from user cap to restricted access, pending new user accounts are not automatically removed.
The users remain blocked until an administrator approves them.

After you turn on restricted access, it governs whether a pending user approval can proceed:

- On the Premium tier, restricted access blocks the pending approval, because users without any group or project membership are billable.
- On the Ultimate tier, restricted access does not block the pending approval, because users without any group or project membership are non-billable. However, after an administrator approves them, restricted access prevents adding the user to a group or project with a billable role if no seats are available.

## Buy more seats

{{< details >}}

- Offering: GitLab.com, GitLab Self-Managed

{{< /details >}}

Your subscription cost is based on the maximum number of seats you use during the billing period.

If restricted access is:

- On, when there are no seats left in your subscription you must purchase more seats for groups to add new billable users.
- Off, when there are no seats left in your subscription groups can continue to add billable users.
  GitLab bills you for the overage.

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

You can view and manage your [billable users](../administration/moderate_users.md#billable-users)
and [license usage](../administration/license_usage.md).

To increase the number of users covered by your license, buy more seats
during the subscription period. The cost of seats added during the subscription
period is prorated from the date of purchase through to the end of the subscription
period. You can continue to add users even if you reach the number of users in
license count. GitLab bills you for the overage.

If your subscription was activated with an activation code, the additional seats are reflected in
your instance immediately. If you're using a license file, you receive an updated file.
To add the seats, add the license file to your instance.

If [LDAP is integrated with GitLab](../administration/auth/ldap/_index.md), anyone in the configured domain can sign up for a GitLab account.
This can result in an unexpected bill at time of renewal.
If new user accounts are allowed on your instance, anyone who can access the instance can sign up for an account.

To prevent unexpected overages, see the best practices for seat management.

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
which will be included in your next invoice.

### Seat usage alerts

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/348481) in GitLab 15.2 [with a feature flag](../administration/feature_flags/_index.md) named `seat_flag_alerts`.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/362041) in GitLab 15.4. Feature flag `seat_flag_alerts` removed.

{{< /history >}}

If you have the Owner role for a top-level group that is linked to a subscription enrolled in
quarterly subscription reconciliations,
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

1. In the top bar, select **Search or go to** and find your group.
1. In the left sidebar, select **Settings** > **Usage quotas**.
1. Select the **Seats** tab.

For each user, a list shows groups and projects where the user is a direct member.

- **Group invite** indicates the user is a member of a [group invited to a group](../user/project/members/sharing_projects_groups.md#invite-a-group-to-a-group).
- **Project invite** indicates the user is a member of a [group invited to a project](../user/project/members/sharing_projects_groups.md#invite-a-group-to-a-project).

The data in seat usage listing, **Seats in use**, and **Seats in subscription** are updated live.
The counts for **Max seats used** and **Seats owed** are updated once per day.

#### View billing information

To view your subscription information and a summary of seat counts:

1. In the top bar, select **Search or go to** and find your group.
1. In the left sidebar, select **Settings** > **Billing**.

- The usage statistics are updated once per day, which may cause a difference between the information
  in the **Usage quotas** page and the **Billing page**.
- The **Last login** field is updated when a user signs in after they have signed out. If there is an active session
  when a user re-authenticates (for example, after a 24 hour SAML session timeout), this field is not updated.

### Search users' seat usage

You can view the users that use seats on your subscription.
To search for a user's seat usage:

1. In the top bar, select **Search or go to** and find your group.
1. In the left sidebar, select **Settings** > **Usage quotas**.
1. On the **Seats** tab, in the search field, enter the user's name or username.
   The search string must have minimum three characters.

The search returns a list of users whose first name, last name, or username match the search string.

For example, for a user with the first name Amir,
the search string `ami` results in a match, but `amr` does not.

### Export seat usage data

To export seat usage data as a CSV file:

1. In the top bar, select **Search or go to** and find your group.
1. In the left sidebar, select **Settings** > **Usage quotas**.
1. In the **Seats** tab, select **Export list**.

### Export seat usage history

Prerequisites:

- You must have the Owner role for the group.

To export seat usage history as a CSV file:

1. In the top bar, select **Search or go to** and find your group.
1. In the left sidebar, select **Settings** > **Usage quotas**.
1. In the **Seats** tab, select **Export seat usage history**.

The generated list contains all seats being used,
and is not affected by the current search.

### Remove users from subscription

To remove a billable user from your GitLab.com subscription:

1. In the top bar, select **Search or go to** and find your group.
1. In the left sidebar, select **Settings** > **Billing**.
1. In the **Seats currently in use** section, select **See usage**.
1. In the row for the user you want to remove, on the right side, select **Remove user**.
1. Re-type the username and select **Remove user**.

If you add a member to a group by sharing the group with another group, you can't remove the member by using this method. Instead, you can either:

- [Remove the member from the shared group](../user/group/_index.md#remove-a-member-from-the-group).
- [Remove the invited group](../user/project/members/sharing_projects_groups.md#remove-an-invited-group).

## Enterprise Agile Planning

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

GitLab Enterprise Agile Planning is an add-on that helps bring non-engineering users into the same
DevSecOps platform where engineers build, test, secure, and deploy code.
The add-on enables cross-team collaboration between developers and non-developers
without having to purchase GitLab Ultimate licenses for non-engineering team members.

With Enterprise Agile Planning seats, non-engineering team members can participate in planning
workflows, measure software delivery velocity and impact with Value Stream Analytics, and use
executive dashboards to drive organizational visibility.

For more information about Enterprise Agile Planning seats and how to purchase them,
contact your [GitLab sales representative](https://customers.gitlab.com/contact_us).

### Using Enterprise Agile Planning seats

A user occupies an Enterprise Agile Planning seat if:

- Your subscription includes purchased Enterprise Agile Planning seats.
- The highest [role](../user/permissions.md#default-roles) the user has across the top-level group, its subgroups, and projects is Planner.

A user occupies an Ultimate seat instead of an Enterprise Agile Planning seat if either:

- Your subscription does not include purchased Enterprise Agile Planning seats.
- The user with the Planner role is assigned a higher role (such as Developer or Maintainer) anywhere in the organization hierarchy.

To use your purchased Enterprise Agile Planning seats, you must first assign the Planner role to users
in the [group](../user/group/_index.md#add-users-to-a-group) or [project](../user/project/members/_index.md#add-users-to-a-project).

To prevent users with the Planner role from being assigned a different role and consequently consume Ultimate seats,
you can use [global SAML group membership lock](../user/group/saml_sso/group_sync.md).

You can view the number of Enterprise Agile Planning seats used in your
[subscription details](manage_subscription.md#view-subscription) and in [Customers Portal](billing_account.md).
On GitLab Self-Managed, you can also view the total number of users by role in [user statistics](../administration/admin_area.md#users-statistics).

## Best practices

To effectively manage your subscription seats and control costs, follow these best practices.

Initial setup:

- [Turn off new user account creation](../administration/settings/sign_up_restrictions.md#disable-new-user-account-creation).
- Automatically block new users through [LDAP](../administration/auth/ldap/_index.md#basic-configuration-settings) or [OmniAuth](../integration/omniauth.md#configure-common-settings).
- Require approval for [new accounts](../administration/settings/sign_up_restrictions.md#require-administrator-approval-for-new-user-accounts) and [role promotions](../administration/settings/sign_up_restrictions.md#turn-on-administrator-approval-for-role-promotions) to maintain control over seat allocation from the start.
- Use seat controls to turn on restricted access, or set a user cap for a group or an instance to prevent unintended seat usage.
- Assign non-billable roles like Guest (on Free and Ultimate) or Minimal Access when possible to minimize seat usage.

Regular activities:

- Monitor seat usage and user statistics regularly to identify potential overages.
- Act on seat usage alerts that notify you when seats are running low.
- Automatically deactivate or remove dormant members to free up seats for active team members.

Strategic planning:

- Use Enterprise Agile Planning seats for non-engineering team members instead of full Ultimate seats.
- Plan ahead for growth by buying seats when approaching your limit.
- Export and analyze your seat usage history to forecast future needs.
