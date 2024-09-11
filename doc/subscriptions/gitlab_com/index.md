---
stage: Fulfillment
group: Subscription Management
description: Seat usage, compute minutes, storage limits, renewal info.
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# GitLab.com subscription

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com

NOTE:
The GitLab SaaS subscription is being renamed to GitLab.com. During this transition, you might see references to GitLab SaaS and GitLab.com in the UI and documentation.

GitLab.com is the GitLab multi-tenant software-as-a-service (SaaS) offering.
You don't need to install anything to use GitLab.com, you only need to
[sign up](https://gitlab.com/users/sign_up). When you sign up, you choose:

- [A subscription](https://about.gitlab.com/pricing/).
- [The number of seats you want](#how-seat-usage-is-determined).

The subscription determines which features are available for your private projects. Organizations with public open source projects can actively apply to our [GitLab for Open Source Program](https://about.gitlab.com/solutions/open-source/join/).

Qualifying open source projects also get 50,000 compute minutes and free access to the **Ultimate** tier
through the [GitLab for Open Source program](https://about.gitlab.com/solutions/open-source/).

## Obtain a GitLab.com subscription

A GitLab.com subscription applies to a top-level group.
Members of every subgroup and project in the group:

- Can use the features of the subscription.
- Consume seats in the subscription.

To subscribe to GitLab.com:

1. View the [GitLab.com feature comparison](https://about.gitlab.com/pricing/feature-comparison/)
   and decide which tier you want.
1. Create a user account for yourself by using the
   [sign up page](https://gitlab.com/users/sign_up).
1. Create a [group](../../user/group/index.md#create-a-group). Your subscription tier applies to the top-level group, its subgroups, and projects.
1. Create additional users and
   [add them to the group](../../user/group/index.md#add-users-to-a-group). The users in this group, its subgroups, and projects can use
   the features of your subscription tier, and they consume a seat in your subscription.
1. On the left sidebar, select **Settings > Billing** and choose a tier. You are taken to the Customers Portal.
1. Fill out the form to complete your purchase.

## View your GitLab.com subscription

Prerequisites:

- You must have the Owner role for the group.

To see the status of your GitLab.com subscription:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > Billing**.

The following information is displayed:

| Field                       | Description |
|:----------------------------|:------------|
| **Seats in subscription**   | If this is a paid plan, represents the number of seats you've bought for this group. |
| **Seats currently in use**  | Number of seats in use. Select **See usage** to see a list of the users using these seats. |
| **Maximum seats used**          | Highest number of seats you've used. |
| **Seats owed**              | **Max seats used** minus **Seats in subscription**. |
| **Subscription start date** | Date your subscription started. |
| **Subscription end date**   | Date your current subscription ends. |

## How seat usage is determined

A GitLab.com subscription uses a concurrent (_seat_) model. You pay for a
subscription according to the maximum number of users assigned to the top-level group or its children during the billing period. You can
add and remove users during the subscription period without incurring additional charges, as long as the total users
at any given time doesn't exceed the subscription count. If the total users exceeds your subscription count, you will incur an overage
which must be paid at your next [reconciliation](../quarterly_reconciliation.md).

A top-level group can be [changed](../../user/group/manage.md#change-a-groups-path) like any other group.

### Billable users

Billable users count toward the number of subscription seats purchased in your subscription.

A user is not counted as a billable user if:

- They are pending approval.
- They have the [Guest role on an Ultimate subscription](#free-guest-users).
- They are a [banned member](../../user/group/moderate_users.md#ban-a-user).
- They are a [blocked user](../../administration/moderate_users.md#block-a-user).
- The account is a GitLab-created service account:
  - [Ghost User](../../user/profile/account/delete_account.md#associated-records).
  - Bots such as:
    - [Support Bot](../../user/project/service_desk/configure.md#support-bot-user).
    - [Bot users for projects](../../user/project/settings/project_access_tokens.md#bot-users-for-projects).
    - [Bot users for groups](../../user/group/settings/group_access_tokens.md#bot-users-for-groups).

Seat usage is reviewed [quarterly or annually](../quarterly_reconciliation.md).

If a user goes to a different top-level group (one they have created themselves, for example)
and that group does not have a paid subscription, they would not see any of the paid features.

It is also possible for users to belong to two different top-level groups with different subscriptions.
In this case, they would see only the features available to that subscription.

### View seat usage

To view a list of seats being used:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > Usage Quotas**.
1. On the **Seats** tab, view usage information.

For each user, a list shows groups and projects where the user is a direct member.

- **Group invite** indicates the user is a member of a [group shared with a group](../../user/project/members/sharing_projects_groups.md#invite-a-group-to-a-group).
- **Project invite** indicates the user is a member of a [group shared with a project](../../user/project/members/sharing_projects_groups.md#invite-a-group-to-a-project).

The data in seat usage listing, **Seats in use**, and **Seats in subscription** are updated live.
The counts for **Max seats used** and **Seats owed** are updated once per day.

To view your subscription information and a summary of seat counts:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > Billing**.

- The usage statistics are updated once per day, which may cause a difference between the information
  in the **Usage Quotas** page and the **Billing page**.
- The **Last login** field is updated when a user signs in after they have signed out. If there is an active session
  when a user re-authenticates (for example, after a 24 hour SAML session timeout), this field is not updated.

### Search seat usage

To search billable users:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > Usage Quotas**.
1. On the **Seats tab**, enter a string in the search field. A minimum of 3
characters are required.

The search returns those users whose first name, last name, or username contain the search string.

For example:

| First name | Search string | Match ? |
|:-----------|:--------------|:--------|
| Amir       | `ami`         | Yes     |
| Amir       | `amr`         | No      |

### Export seat usage

To export seat usage data as a CSV file:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > Usage Quotas**.
1. In the **Seats** tab, select **Export list**.

### Export seat usage history

Prerequisites:

- You must have the Owner role for the group.

To export seat usage history as a CSV file:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > Usage Quotas**.
1. In the **Seats** tab, select **Export seat usage history**.

The generated list contains all seats being used,
and is not affected by the current search.

## Seats owed

If the number of billable users exceeds the number of **seats in subscription**, known
as the number of **seats owed**, you must pay for the excess number of users.

For example, if you purchase a subscription for 10 users:

| Event                                              | Billable members | Maximum users |
|:---------------------------------------------------|:-----------------|:--------------|
| Ten users occupy all 10 seats.                     | 10               | 10            |
| Two new users join.                                | 12               | 12            |
| Three users leave and their accounts are removed.  | 9                | 12            |

Seats owed = 12 - 10 (Maximum users - users in subscription)

### Free Guest users

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

In the **Ultimate** tier, users who are assigned the Guest role do not consume a seat.
The user must not be assigned any other role, anywhere in the instance or in the namespace for GitLab.com.

- If your project is private or internal, a user with the Guest role has
  [a set of permissions](../../user/permissions.md#project-members-permissions).
- If your project is public, all users, including those with the Guest role
  can access your project.
- For GitLab.com, if a user with the Guest role creates a project in their personal namespace, it does not consume a seat. The project is under the user's personal namespace and does not relate to the group with the Ultimate subscription.

### Add seats to your subscription

Your subscription cost is based on the maximum number of seats you use during the billing period.
Even if you reach the number of seats in your subscription, you can continue to add users.
GitLab [bills you for the overage](../quarterly_reconciliation.md).

To add seats to a subscription:

1. Sign in to the [Customers Portal](https://customers.gitlab.com/).
1. Go to the **Subscriptions & purchases** page.
1. Select **Add seats** on the relevant subscription card.
1. Enter the number of additional users.
1. Review the **Purchase summary** section. The system lists the total price for all users on the system and a credit for what you've already paid. You are only charged for the net change.
1. Enter your payment information.
1. Check the **I accept the Privacy Statement and Terms of Service** checkbox.
1. Select **Purchase seats**.

The following is emailed to you:

- A payment receipt. You can also access this information in the Customers Portal under
  [**Invoices**](https://customers.gitlab.com/invoices).

### Remove users from your subscription

To remove a billable user from your subscription:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > Billing**.
1. In the **Seats currently in use** section, select **See usage**.
1. In the row for the user you want to remove, on the right side, select **Remove user**.
1. Re-type the username and select **Remove user**.

If you add a member to a group by using the [share a group with another group](../../user/project/members/sharing_projects_groups.md#invite-a-group-to-a-group) feature, you can't remove the member by using this method. Instead, you can either:

- Remove the member from the shared group. You must be a group owner to do this.
- From the group's membership page, remove access from the entire shared group.

## Seat usage alerts

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/348481) in GitLab 15.2 [with a flag](../../administration/feature_flags.md) named `seat_flag_alerts`.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/362041) in GitLab 15.4. Feature flag `seat_flag_alerts` removed.

If you have the Owner role of the top-level group, an alert notifies you
of your total seat usage.

The alert displays on group, subgroup, and project
pages, and only for top-level groups linked to subscriptions enrolled
in [quarterly subscription reconciliations](../quarterly_reconciliation.md).
After you dismiss the alert, it doesn't display until another seat is used.

The alert displays based on the following seat usage. You cannot configure the
amounts at which the alert displays.

| Seats in subscription | Alert displays when           |
|-----------------------|----------------------|
| 0-15                  | One seat remains.     |
| 16-25                 | Two seats remain.    |
| 26-99                 | 10% of seats remain. |
| 100-999               | 8% of seats remain.  |
| 1000+                 | 5% of seats remain.  |

## Change the linked group

To change the group linked to a GitLab.com subscription:

1. Sign in to the [Customers Portal](https://customers.gitlab.com/customers/sign_in) with a
   [linked](../customers_portal.md#link-a-gitlabcom-account) GitLab.com account.
1. Do one of the following:
   - If the subscription is not linked to a group, select **Link subscription to a group**.
   - If the subscription is already linked to a group, select **Subscription actions** (**{ellipsis_v}**) > **Change linked group**.
1. Select the desired group from the **New Namespace** dropdown list. For a group to appear here, you must have the Owner role for that group.
1. If the [total number of users](#view-seat-usage) in your group exceeds the number of seats in your subscription,
   you are prompted to pay for the additional users. Subscription charges are calculated based on
   the total number of users in a group, including its subgroups and nested projects.

   If you purchased your subscription through an authorized reseller, you are unable to pay for additional users.
   You can either:

   - Remove additional users, so that no overage is detected.
   - Contact the partner to purchase additional seats now or at the end of your subscription term.

1. Select **Confirm changes**.

Only one namespace can be linked to a subscription.

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For a demo, see [Linking GitLab Subscription to the Namespace](https://youtu.be/8iOsN8ajBUw).

### Transfer restrictions

Changing the linked namespace is not supported for all subscription types.

You cannot transfer:

- An expired or trial subscription.
- A subscription with compute minutes which is already linked to a namespace.
- A subscription with a Premium or Ultimate plan to a namespace which already has a Premium or Ultimate plan.
- A subscription with a GitLab Duo add-on to a namespace which already has a subscriptions with a GitLab Duo add-on.

## Upgrade your GitLab.com subscription tier

To upgrade your [GitLab tier](https://about.gitlab.com/pricing/):

1. Sign in to the [Customers Portal](https://customers.gitlab.com/customers/sign_in).
1. Select **Upgrade** on the relevant subscription card.
1. Select the desired upgrade.
1. Confirm the active form of payment, or add a new form of payment.
1. Check the **I accept the Privacy Statement and Terms of Service** checkbox.
1. Select **Confirm purchase**.

When the purchase has been processed, you receive confirmation of your new subscription tier.

## Subscription expiry

When your subscription expires, you can continue to use paid features of GitLab for 14 days.
On the 15th day, paid features are no longer available. You can
continue to use free features.

For example, if a subscription has a start date of January 1, 2024 and an end date of January 1, 2025:

- It expires at 11:59:59 PM UTC December 31, 2024.
- It is considered expired from 12:00:00 AM UTC January 1, 2025.
- The grace period of 14 days starts at 12:00:00 AM UTC January 1, 2025 and ends at 11:59:59 PM UTC January 14, 2025.
- Paid features are no longer available as of 12:00:00 AM UTC January 15, 2025.

To resume paid feature functionality, purchase a new subscription.

## Renew your GitLab.com subscription

30 days before a subscription expires, a banner with the subscription expiry date displays for group owners in the GitLab user interface.
You also receive [email notifications](../self_managed/index.md#email-notifications) before a subscription automatically renews.

Before you renew your GitLab.com subscription, you should [review your account](../self_managed/index.md#review-your-account).

You can renew your subscription [manually](../self_managed/index.md#renew-subscription-manually) or automatically.
Your updated subscription is applied to your namespace.
The renewal period start date is displayed on the group Billing page under **Next subscription term start date**.

You can view and [manage renewal invoice](../self_managed/index.md#manage-renewal-invoice) at any time.

### Renew for fewer seats

You can renew your subscription for fewer seats, as long as the seat total is equal to or greater than the billable user quantity at the time of renewal.
If you want to renew for fewer seats, you can do either of the following:

- [Manually renew](../self_managed/index.md#renew-subscription-manually) within 15 days of subscription renewal date, and **specify the desired seat quantity** on the renewal page. To reduce billable user quantity, [remove users from your subscription](#remove-users-from-your-subscription).
- Disable automatic subscription renewal and work with the Sales team to renew it for the number of seats you want.

### Automatic subscription renewal

When a subscription is set to auto-renew, it renews automatically at midnight UTC on the expiration date without a gap in available service.
Subscriptions purchased through the Customers Portal or GitLab.com are set to auto-renew by default,
but you can [disable automatic subscription renewal](../self_managed/index.md#enable-or-disable-automatic-subscription-renewal).

The number of seats is adjusted to fit the [number of billable users in your group](#view-seat-usage) at the time of renewal,
if that number is higher than the current subscription quantity.

## Add or change the contacts for your subscription

Contacts can renew a subscription, cancel a subscription, or transfer the subscription to a different namespace.

For information about how to transfer ownership of the Customers Portal account to another person, see
[Change profile owner information](../customers_portal.md#change-profile-owner-information).

To add a secondary contact for your subscription:

1. Ensure an account exists in the
   [Customers Portal](https://customers.gitlab.com/customers/sign_in) for the user you want to add.
1. [Create a ticket with the Support team](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=360000071293). Include any relevant material in your request.

## Compute

Compute is the resource consumed when running [pipelines](../../ci/pipelines/index.md)
on GitLab instance runners.

Refer to [Compute usage](../../ci/pipelines/compute_minutes.md)
for more information.

### Purchase additional compute minutes

You can [purchase additional compute minutes](../../ci/pipelines/compute_minutes.md#purchase-additional-compute-minutes)
for your personal or group namespace. Compute minutes are a **one-time purchase**, so they do not renew.

## Add-on subscription for additional Storage

Projects have a free storage quota of 10 GiB. To exceed this quota you must first
purchase one or more storage subscription units. Each unit provides 10 GiB of additional
storage per namespace. A storage subscription is renewed annually. For more details, see
[Storage](../../user/usage_quotas.md).

### Purchase more storage

Prerequisites:

- You must have the Owner role.

You can purchase a storage subscription for your personal or group namespace.

NOTE:
Storage subscriptions **renew automatically each year**.
You can [disable automatic subscription renewal](../self_managed/index.md#enable-or-disable-automatic-subscription-renewal).

#### For your personal namespace

1. Sign in to GitLab.com.
1. From either your personal homepage or the group's page, go to **Settings > Usage Quotas**.
1. Select **Storage** tab.
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

#### For your group namespace

If you're using GitLab.com, you can purchase additional storage so your
pipelines aren't blocked after you have used all your storage from your
main quota. You can find pricing for additional storage on the
[GitLab Pricing page](https://about.gitlab.com/pricing/).

To purchase additional storage for your group on GitLab.com:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > Usage Quotas**.
1. Select **Storage** tab.
1. Select **Buy storage**. You are taken to the Customers Portal.
1. In the **Subscription details** section, enter the desired quantity of storage packs.
1. In the **Customer information** section, verify your address.
1. In the **Billing information** section, select a payment method from the dropdown list.
1. Select the **Privacy Statement** and **Terms of Service** checkboxes.
1. Select **Buy storage**.

After your payment is processed, the extra storage is available for your group namespace.

To confirm the available storage, go to your group, and then select
**Settings > Usage Quotas** and select the **Storage** tab.

The **Purchased storage available** total is incremented by the amount purchased. All locked
projects are unlocked and their excess usage is deducted from the additional storage.

## Enterprise Agile Planning

GitLab Enterprise Agile Planning is an add-on that helps bring non-technical users into the same
DevSecOps platform where engineers build, test, secure, and deploy code.
The add-on enables cross-team collaboration between developers and non-developers without having to
purchase full GitLab licenses for non-engineering team members.
With Enterprise Agile Planning seats, non-engineering team members can participate in planning
workflows, measure software delivery velocity and impact with Value Stream Analytics, and use
executive dashboards to drive organizational visibility.

### Purchase additional Enterprise Agile Planning seats

Contact your [GitLab sales representative](https://about.gitlab.com/sales/) for more information.

## Contact Support

Learn more about:

- The tiers of [GitLab Support](https://about.gitlab.com/support/).
- [Submit a request via the Support Portal](https://support.gitlab.com/hc/en-us/requests/new).

We also encourage you to search our project trackers for known issues and
existing feature requests in the [GitLab](https://gitlab.com/gitlab-org/gitlab/-/issues/) project.

These issues are the best avenue for getting updates on specific product plans
and for communicating directly with the relevant GitLab team members.
