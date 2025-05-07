---
stage: Fulfillment
group: Subscription Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Buy, view, and renew your GitLab subscriptions.
title: Manage subscription
---

## Buy a subscription

You can buy a subscription for GitLab.com or GitLab Self-Managed.

### For GitLab.com

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com

{{< /details >}}

A GitLab.com subscription applies to a top-level group.
Members of every subgroup and project in the group:

- Can use the features of the subscription.
- Consume seats in the subscription.

To subscribe to GitLab.com:

1. View the [GitLab.com feature comparison](https://about.gitlab.com/pricing/feature-comparison/)
   and decide which tier you want.
1. Create a user account for yourself by using the
   [sign up page](https://gitlab.com/users/sign_up).
1. Create a [group](../user/group/_index.md#create-a-group). Your subscription tier applies to the top-level group, its subgroups, and projects.
1. Create additional users and
   [add them to the group](../user/group/_index.md#add-users-to-a-group). The users in this group, its subgroups, and projects can use
   the features of your subscription tier, and they consume a seat in your subscription.
1. On the left sidebar, select **Settings > Billing** and choose a tier. You are taken to the Customers Portal.
1. Fill out the form to complete your purchase.

### For GitLab Self-Managed

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

To subscribe to GitLab for a GitLab Self-Managed instance:

1. Go to the [Pricing page](https://about.gitlab.com/pricing/) and select a self-managed plan. You are redirected to the [Customers Portal](https://customers.gitlab.com/) to complete your purchase.
1. After purchase, an activation code is sent to the email address associated with the Customers Portal account.
   You must [add this code to your GitLab instance](../administration/license.md).

{{< alert type="note" >}}

If you're purchasing a subscription for an existing **Free** GitLab Self-Managed
instance, ensure you're purchasing enough seats to
[cover your users](../administration/admin_area.md#administering-users).

{{< /alert >}}

## View subscription

### For GitLab.com

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com

{{< /details >}}

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
| **Maximum seats used**      | Highest number of seats you've used. |
| **Seats owed**              | **Max seats used** minus **Seats in subscription**. |
| **Subscription start date** | Date your subscription started. |
| **Subscription end date**   | Date your current subscription ends. |

### For GitLab Self-Managed

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

Prerequisites:

- You must be an administrator.

You can view the status of your subscription:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Subscription**.

The **Subscription** page includes the following information:

- Licensee
- Plan
- When it was uploaded, started, and when it expires
- Number of users in subscription
- Number of billable users
- Maximum users
- Number of users over subscription

## Upgrade subscription tier

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed

{{< /details >}}

To upgrade your [GitLab tier](https://about.gitlab.com/pricing/):

1. Sign in to the [Customers Portal](https://customers.gitlab.com/customers/sign_in).
1. Select **Upgrade plan** on the relevant subscription card.
1. Confirm the active form of payment, or add a new form of payment.
1. Select the **I accept the Privacy Statement and Terms of Service** checkbox.
1. Select **Upgrade subscription**.

The following is emailed to you:

- A payment receipt. You can also access this information in the Customers Portal under
  [**Invoices**](https://customers.gitlab.com/invoices).
- On GitLab Self-Managed, a new activation code for your license.

On GitLab Self-Managed, the new tier takes effect on the next subscription sync.
You can also [synchronize your subscription manually](#subscription-data-synchronization)
to upgrade right away.

## Subscription data synchronization

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

Prerequisites:

- GitLab Enterprise Edition (EE).
- Connection to the internet, and must not have an offline environment.
- [Activated](../administration/license.md) your instance with an activation code.

Your [subscription data](#subscription-data) is automatically synchronized once
a day between your GitLab Self-Managed instance and GitLab.

At approximately 3:00 AM (UTC), this daily synchronization job sends
[subscription data](#subscription-data) to the Customers Portal. For this reason,
updates and renewals might not apply immediately.

The data is sent securely through an encrypted HTTPS connection to
`customers.gitlab.com` on port `443`. If the job fails, it retries up to 12 times
over approximately 17 hours.

After you have set up automatic data synchronization, the following processes are
also automated.

- [Quarterly subscription reconciliation](quarterly_reconciliation.md).
- Subscription renewals.
- Subscription updates, such as adding more seats or upgrading a GitLab tier.

### Manually synchronize subscription data

You can also manually synchronize subscription data at any time.

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Subscription**.
1. In the **Subscription details** section, select **Sync** ({{< icon name="retry" >}}).

A synchronization job is then queued. When the job finishes, the subscription
details are updated.

### Subscription data

The daily synchronization job sends the following information to the
Customers Portal:

- Date
- Timestamp
- License key, with the following encrypted within the key:
  - Company name
  - Licensee name
  - Licensee email
- Historical [maximum user count](self_managed/_index.md#maximum-users)
- [Billable users count](self_managed/_index.md#billable-users)
- GitLab version
- Hostname
- Instance ID

Additionally, we also send add-on metrics such as:

- Add-on type
- Purchased seats
- Assigned seats

Example of a license sync request:

```json
{
  "gitlab_version": "14.1.0-pre",
  "timestamp": "2021-06-14T12:00:09Z",
  "date": "2021-06-14",
  "license_key": "XXX",
  "max_historical_user_count": 75,
  "billable_users_count": 75,
  "hostname": "gitlab.example.com",
  "instance_id": "9367590b-82ad-48cb-9da7-938134c29088",
  "add_on_metrics": [
    {
      "add_on_type": "duo_enterprise",
      "purchased_seats": 100,
      "assigned_seats": 50
    }
  ]
}
```

## Link subscription to a group

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com

{{< /details >}}

To change the group linked to a GitLab.com subscription:

1. Sign in to the [Customers Portal](https://customers.gitlab.com/customers/sign_in) with a
   [linked](customers_portal.md#link-a-gitlabcom-account) GitLab.com account.
1. Do one of the following:
   - If the subscription is not linked to a group, select **Link subscription to a group**.
   - If the subscription is already linked to a group, select **Subscription actions** ({{< icon name="ellipsis_v" >}}) > **Change linked group**.
1. Select the desired group from the **New Namespace** dropdown list. For a group to appear here, you must have the Owner role for that group.
1. If the [total number of users](gitlab_com/_index.md#view-seat-usage) in your group exceeds the number of seats in your subscription,
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

You can change the linked namespace, however this is not supported for all subscription types.

You cannot transfer:

- An expired or trial subscription.
- A subscription with compute minutes which is already linked to a namespace.
- A subscription with a Premium or Ultimate plan to a namespace which already has a Premium or Ultimate plan.
- A subscription with a GitLab Duo add-on to a namespace which already has a subscriptions with a GitLab Duo add-on.

## Enterprise Agile Planning

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

GitLab Enterprise Agile Planning is an add-on that helps bring non-technical users into the same
DevSecOps platform where engineers build, test, secure, and deploy code.
The add-on enables cross-team collaboration between developers and non-developers without having to
purchase full GitLab licenses for non-engineering team members.
With Enterprise Agile Planning seats, non-engineering team members can participate in planning
workflows, measure software delivery velocity and impact with Value Stream Analytics, and use
executive dashboards to drive organizational visibility.

To purchase additional Enterprise Agile Planning seats, contact your
[GitLab sales representative](https://customers.gitlab.com/contact_us) for more information.
