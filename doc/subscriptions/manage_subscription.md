---
stage: Fulfillment
group: Subscription Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Buy, view, and renew your GitLab subscriptions.
title: Manage subscription
---

## Buy a subscription

You can buy a subscription for GitLab.com or GitLab Self-Managed.
The subscription determines which features are available for your private projects.

After you subscribe to GitLab, you can manage the details of your subscription.
If you experience any issues, see the [troubleshooting GitLab subscription](gitlab_com/gitlab_subscription_troubleshooting.md).

Organizations with public open source projects can apply to the [GitLab for Open Source program](community_programs.md#gitlab-for-open-source).

### For GitLab.com

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com

{{< /details >}}

GitLab.com is the GitLab multi-tenant software-as-a-service (SaaS) offering.
You don't need to install anything to use GitLab.com, you only need to [sign up](https://gitlab.com/users/sign_up).
When you sign up, you choose:

- [A subscription](https://about.gitlab.com/pricing/).
- The number of seats you want.

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
1. On the left sidebar, select **Settings** > **Billing** and choose a tier. You are taken to the Customers Portal.
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
1. Select **Settings** > **Billing**.

The following information is displayed:

| Field                       | Description |
|:----------------------------|:------------|
| **Seats in subscription**   | If this is a paid plan, represents the number of seats you've bought for this group. |
| **Seats currently in use**  | Number of seats in use. Select **See usage** to see a list of the users using these seats. |
| **Maximum seats used**      | Highest number of seats you've used. |
| **Seats owed**              | **Max seats used** - **Seats in subscription**. |
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

1. On the left sidebar, at the bottom, select **Admin**. If you've [turned on the new navigation](../user/interface_redesign.md#turn-new-navigation-on-or-off), in the upper-right corner, select your avatar and then select **Admin**.
1. Select **Subscription**.

The **Subscription** page includes the following information:

- Licensee
- Plan
- When it was uploaded, started, and when it expires
- Number of users in subscription
- Number of billable users
- Maximum users
- Number of users over subscription

## Review your account

You should regularly review your billing account settings and purchasing information.

To review your billing account settings:

1. Sign in to the [Customers Portal](https://customers.gitlab.com/customers/sign_in).
1. Select **Billing account settings**.
1. Verify or update:
   - Under **Payment methods**, the credit card on file.
   - Under **Company information**, the subscription and billing contact details.
1. Save any changes.

You should also regularly review your user accounts to make sure that you are only
renewing for the correct number of active billable users. Inactive user accounts:

- Might count as billable users. You pay more than
  you should if you renew inactive user accounts.
- Can be a security risk. A regular review helps reduce this risk.

For more information, see the documentation on:

- [User statistics](../administration/admin_area.md#users-statistics).
- [License usage](../administration/license_usage.md).
- [Managing users and subscription seats](manage_users_and_seats.md#manage-users-and-subscription-seats).

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

## Renew subscription

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed

{{< /details >}}

Before your subscription renewal date, you should review your account to check
your current seat usage and billable users.

You can renew your subscription automatically or manually.
You should renew your subscription manually if you want to either:

- Renew for fewer seats.
- Increase or decrease the quantities of products being renewed.
- Remove add-on products no longer needed for the renewed subscription term.
- Upgrade the subscription tier.

The renewal period start date is displayed on the group Billing page under **Next subscription term start date**.

Contact the:

- [Support team](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=360000071293)
if you need help accessing the Customers Portal or changing the contact person who manages your subscription.
- [Sales team](https://customers.gitlab.com/contact_us) if you need help renewing your subscription.

### Check when subscription expires

15 days before a subscription expires, a banner with the subscription expiry date displays for
administrators in the GitLab user interface.

You cannot manually renew your subscription more than 15 days before the subscription
expires. To check when you can renew:

1. Sign in to the [Customers Portal](https://customers.gitlab.com/customers/sign_in).
1. Select **Subscription actions** ({{< icon name="ellipsis_v" >}}), then select **Renew subscription**
   to view the date you can renew.

### Renew automatically

Prerequisites:

- For GitLab Self-Managed, you must [synchronize subscription data](#subscription-data-synchronization) and review your account at least two days before renewal to ensure your changes are synchronized.

When a subscription is set to auto-renew, it renews automatically at midnight UTC on the expiration date without a gap in available service.
You receive [email notifications](#renewal-notifications) before a subscription automatically renews.

Seat counts do not decrease automatically at renewal time. If you have more billable users than your current subscription quantity at renewal time, your seat count increases automatically to match the current number of users in your
[group](manage_users_and_seats.md#view-seat-usage) or [instance](manage_users_and_seats.md#view-users).
To avoid unexpectedly renewing your subscription for more seats, learn how to [renew for fewer seats](#renew-for-fewer-seats).

Subscriptions purchased through the Customers Portal are set to auto-renew by default,
but you can [turn off automatic subscription renewal](#turn-on-or-turn-off-automatic-subscription-renewal).

#### Turn on or turn off automatic subscription renewal

You can use the Customers Portal to turn on or turn off automatic subscription renewal:

1. Sign in to the [Customers Portal](https://customers.gitlab.com/customers/sign_in).
   You are taken to the **Subscriptions & purchases** page.
1. Check the subscription card:
   - If the card displays **Expires on DATE**, your subscription is not
     set to automatically renew. To enable automatic renewal, in
     **Subscription actions** ({{< icon name="ellipsis_v" >}}), select **Turn on auto-renew**.
   - If the card displays **Auto-renews on DATE**, your subscription is set to
     automatically renew. To disable automatic renewal:
     1. In **Subscription actions** ({{< icon name="ellipsis_v" >}}), select **Cancel subscription**.
     1. Select a reason for canceling.
     1. Optional. In **Would you like to add anything?**, enter any relevant information.
     1. Select **Cancel subscription**.

### Renew manually

To manually renew your subscription:

1. Determine the number of users you need in the next subscription period.
1. Sign in to the [Customers Portal](https://customers.gitlab.com/customers/sign_in).
1. Under your existing subscription, select **Start renewal**. This button does not display
   until 15 days before the subscription expires.
1. If renewing Premium or Ultimate products, in the **Seats** text box, enter the
   total number of user seats you need for the upcoming year.

   {{< alert type="note" >}}

   Make sure this number is equal to, or greater than
   the number of [billable users](manage_users_and_seats.md#billable-users) in the system at the time of renewal.

   {{< /alert >}}

1. Optional. For GitLab Self-Managed, if the maximum number of users in your instance exceeded the number
   you were licensed for in the previous subscription term, the
   [overage](quarterly_reconciliation.md) is due when you renew.

   In the **Users over license** text box, enter the number of
   [users over subscription](manage_users_and_seats.md#users-over-subscription-limit) for the user overage incurred.
1. Optional. If renewing add-on products, review and update the desired quantity. You can also remove products.
1. Optional. If upgrading the subscription tier, select the desired option.
1. Review your renewal details and select **Renew subscription** to complete the
   payment process.
1. For GitLab Self-Managed, on the [Subscriptions & purchases](https://customers.gitlab.com/subscriptions)
   page on the relevant subscription card, select **Copy activation code** to get
   a copy of the renewal term activation code, and [add the activation code](../administration/license.md) to your instance.

To add products to your subscription, [contact the sales team](https://customers.gitlab.com/contact_us).

### Renew for fewer seats

Subscription renewals with fewer seats must have or exceed the current number of billable users.

Before you renew your subscription:

- For GitLab.com,
[reduce the number of billable users](manage_users_and_seats.md#remove-users-from-subscription)
if it exceeds the number of seats you want to renew for.
- For GitLab Self-Managed, [block inactive or unwanted users](../administration/moderate_users.md#block-a-user).

To manually renew your subscription for fewer seats, you can either:

- [Manually renew](#renew-manually) within 15 days of the
  subscription renewal date. Ensure that you specify the seat quantity when you renew.
- [Turn off automatic renewal of your subscription](#turn-on-or-turn-off-automatic-subscription-renewal),
  and contact the [sales team](https://customers.gitlab.com/contact_us) to renew it for the number of seats you want.

### Renewal notifications

15 days before a subscription automatically renews, an email is sent with information
about the renewal.

- If your credit card is expired, the email tells you how to update it.
- If you have any outstanding overages or your subscription is not able to automatically
  renew for any other reason, the email tells you to contact our Sales team or
  manually renew in the Customers Portal.
- If there are no issues, the email specifies the:
  - Names and quantity of the products being renewed.
  - Total amount you owe. If your usage increases before renewal, this amount changes.

### Manage renewal invoice

An invoice is generated for your renewal. To view or download this renewal invoice,
go to the [Customers Portal invoices page](https://customers.gitlab.com/invoices).

If your account has a [saved credit card](billing_account.md#change-your-payment-method),
the card is charged for the invoice amount.

If we are unable to process a payment or the auto-renewal fails for any other reason,
you have 14 days to renew your subscription, after which your GitLab tier is downgraded.

## Expired subscription

Subscriptions expire at the start of the expiration date, 00:00 server time.

For example, if a subscription is valid from January 1, 2024 until January 1, 2025:

- It expires at 11:59:59 PM UTC December 31, 2024.
- It is considered expired from 12:00:00 AM UTC January 1, 2025.

### For GitLab.com

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com

{{< /details >}}

When your subscription expires, paid features are no longer available.
However, you can continue to use free features.
To resume paid feature functionality, renew your subscription.

### For GitLab Self-Managed

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

When your license expires:

- Your instance becomes read-only.
- GitLab locks features, such as Git pushes and issue creation.
- An expiration message is displayed to all instance administrators.

After your license has expired:

- To resume functionality,
  [activate a new subscription](../administration/license_file.md#activate-subscription-during-installation).
- To keep using Free tier features only,
  [remove the expired license](../administration/license_file.md#remove-a-license).

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

1. On the left sidebar, at the bottom, select **Admin**. If you've [turned on the new navigation](../user/interface_redesign.md#turn-new-navigation-on-or-off), in the upper-right corner, select your avatar and then select **Admin**.
1. Select **Subscription**.
1. In the **Subscription details** section, select **Sync** ({{< icon name="retry" >}}).

A synchronization job is then queued. When the job finishes, the subscription
details are updated.

### Subscription data

{{< history >}}

- Unique instance ID [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/189399) in GitLab 18.1.

{{< /history >}}

The daily synchronization job sends the following information to the
Customers Portal:

- Date
- Timestamp
- License key, with the following encrypted within the key:
  - Company name
  - Licensee name
  - Licensee email
- Historical [maximum user count](manage_users_and_seats.md#self-managed-billing-and-usage)
- [Billable users count](manage_users_and_seats.md#billable-users)
- GitLab version
- Hostname
- Instance ID
- Unique instance ID

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
  "unique_instance_id": "a98bab6e-73e3-5689-a487-1e7b89a56901",
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
   [linked](billing_account.md#link-a-gitlabcom-account) GitLab.com account.
1. Do one of the following:
   - If the subscription is not linked to a group, select **Link subscription to a group**.
   - If the subscription is already linked to a group, select **Subscription actions** ({{< icon name="ellipsis_v" >}}) > **Change linked group**.
1. Select the desired group from the **New Namespace** dropdown list. For a group to appear here, you must have the Owner role for that group.
1. If the [total number of users](manage_users_and_seats.md#view-seat-usage) in your group exceeds the number of seats in your subscription,
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

## Add or change subscription contacts

Contacts can renew a subscription, cancel a subscription, or transfer the subscription to a different namespace.

You can [change profile owner information](billing_account.md#change-profile-owner-information)
and [add another billing account manager](billing_account.md#add-a-billing-account-manager).

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
