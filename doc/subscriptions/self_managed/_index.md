---
stage: Fulfillment
group: Subscription Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Billable users, renewal and upgrade info.
title: GitLab Self-Managed subscription
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

After you subscribe to GitLab, you can manage the details of your self-managed subscription.
If you experience any issues, see the [troubleshooting page](../gitlab_com/gitlab_subscription_troubleshooting.md).

## How GitLab bills for users

A GitLab Self-Managed subscription uses a hybrid model. You pay for a subscription
according to the [maximum number](#maximum-users) of users enabled during the
subscription period.

For instances that are not offline or on a closed network, the maximum number of
simultaneous users in the GitLab Self-Managed instance is checked each quarter.

If an instance is unable to generate a quarterly usage report, the existing
[true up model](#users-over-subscription) is used. Prorated charges are not
possible without a quarterly usage report.

### Billable users

Billable users count toward the number of subscription seats purchased in your subscription.

The number of billable users changes when you block, deactivate, or [add](#buy-seats-for-a-subscription) users to your instance during your current subscription period.

A user is not counted as a billable user if:

- They are [deactivated](../../administration/moderate_users.md#deactivate-a-user) or
  [blocked](../../administration/moderate_users.md#block-a-user).
- They are [pending approval](../../administration/moderate_users.md#users-pending-approval).
- They have only the [Minimal Access role](../../user/permissions.md#users-with-minimal-access) on GitLab Self-Managed Ultimate subscriptions.
- They have only the [Guest role on an Ultimate subscription](#free-guest-users).
- They do not have project or group memberships on an Ultimate subscription.
- The account is a GitLab-created account:
  - [Ghost User](../../user/profile/account/delete_account.md#associated-records).
  - Bots such as:
    - [Support Bot](../../user/project/service_desk/configure.md#support-bot-user).
    - [Bot users for projects](../../user/project/settings/project_access_tokens.md#bot-users-for-projects).
    - [Bot users for groups](../../user/group/settings/group_access_tokens.md#bot-users-for-groups).
    - Other [internal users](../../administration/internal_users.md).

The amount of **Billable users** is reported once a day in the **Admin** area.

### Users in subscription

The number of users in subscription represents the number of users included in your current license, based on what you've paid for.
This number remains the same throughout your subscription period unless you purchase more seats.

### Maximum users

The number of maximum users reflects the highest number of billable users on
your system for the current license period.

### Users over subscription

A GitLab subscription is valid for a specific number of seats.
The number of users over subscription shows how many users are in excess of the
number allowed by the subscription, in the current subscription period.

Calculated as `Maximum users` - `Users in subscription` for the current license
term. For example, you purchase a subscription for 10 users.

| Event                                              | Billable users   | Maximum users |
|:---------------------------------------------------|:-----------------|:--------------|
| Ten users occupy all 10 seats.                     | 10               | 10            |
| Two new users join.                                | 12               | 12            |
| Three users leave and their accounts are blocked.  | 9                | 12            |
| Four new users join.                               | 13               | 13            |

Users over subscription = 13 - 10 (Maximum users - users in license)

The users over subscription value is always zero for trial license.

If users over subscription value is above zero, then you have more users in your
GitLab instance than you are licensed for. You must pay for the additional users
[before or at the time of renewal](../quarterly_reconciliation.md). This is
called the _true up_ process. If you do not do this, your license key does not work.

To view the number of users over subscription, go to the **Admin** area.

### Free Guest users

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

In the **Ultimate** tier, users who are assigned the Guest role do not consume a seat.
The user must not be assigned any other role, anywhere in the instance.

- If your project is private or internal, a user with the Guest role has
  [a set of permissions](../../user/permissions.md#project-members-permissions).
- If your project is public, all users, including those with the Guest role
  can access your project.
- A user's highest assigned role is updated asynchronously and may take some time to update.

{{< alert type="note" >}}

If a user creates a project, they are assigned the Maintainer or Owner role.
To prevent a user from creating projects, as an administrator, you can mark the user
as [external](../../administration/external_users.md).

{{< /alert >}}

## View users

View the lists of users in your instance:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Users**.

Select a user to view their account information.

### Check daily and historical billable users

Prerequisites:

- You must be an administrator.

You can get a list of daily and historical billable users in your GitLab instance:

1. [Start a Rails console session](../../administration/operations/rails_console.md#starting-a-rails-console-session).
1. Count the number of users in the instance:

   ```ruby
   User.billable.count
   ```

1. Get the historical maximum number of users on the instance from the past year:

   ```ruby
   ::HistoricalData.max_historical_user_count(from: 1.year.ago.beginning_of_day, to: Time.current.end_of_day)
   ```

### Update daily and historical billable users

Prerequisites:

- You must be an administrator.

You can trigger a manual update of the daily and historical billable users in your GitLab instance.

1. [Start a Rails console session](../../administration/operations/rails_console.md#starting-a-rails-console-session).
1. Force an update of the daily billable users:

   ```ruby
   identifier = Analytics::UsageTrends::Measurement.identifiers[:billable_users]
   ::Analytics::UsageTrends::CounterJobWorker.new.perform(identifier, User.minimum(:id), User.maximum(:id), Time.zone.now)
   ```

1. Force an update of the historical max billable users:

   ```ruby
   ::HistoricalDataWorker.new.perform
   ```

## Manage users and subscription seats

Managing the number of users against the number of subscription seats can be difficult:

- If [LDAP is integrated with GitLab](../../administration/auth/ldap/_index.md), anyone
  in the configured domain can sign up for a GitLab account. This can result in
  an unexpected bill at time of renewal.
- If sign-up is turned on in your instance, anyone who can access the instance can
  sign up for an account.

GitLab has several features to help you manage the number of users. You can:

- [Require administrator approval for new sign ups](../../administration/settings/sign_up_restrictions.md#require-administrator-approval-for-new-sign-ups).
- Automatically block new users, either through
  [LDAP](../../administration/auth/ldap/_index.md#basic-configuration-settings) or
  [OmniAuth](../../integration/omniauth.md#configure-common-settings).
- [Limit the number of billable users](../../administration/settings/sign_up_restrictions.md#user-cap)
  who can sign up or be added to a subscription without administrator approval.
- [Disable new sign-ups](../../administration/settings/sign_up_restrictions.md),
  and instead manage new users manually.
- View a breakdown of users by role in the
  [Users statistics](../../administration/admin_area.md#users-statistics) page.

### Buy seats for a subscription

To increase the number of users covered by your license, buy seats for your subscription
during the subscription period. The cost of seats added during the subscription
period is prorated from the date of purchase through to the end of the subscription
period. You can continue to add users even if you reach the number of users in
license count. GitLab [bills you for the overage](../quarterly_reconciliation.md).

You cannot buy seats for your subscription if either:

- You purchased your subscription through an [authorized reseller](../customers_portal.md#customers-that-purchased-through-a-reseller) (including GCP and AWS marketplaces). Contact the reseller to add more seats.
- You have a multi-year subscription. Contact the [sales team](https://customers.gitlab.com/contact_us) to add more seats.

To buy seats for a subscription:

1. Sign in to the [Customers Portal](https://customers.gitlab.com/).
1. Go to the **Subscriptions & purchases** page.
1. Select **Add seats** on the relevant subscription card.
1. Enter the number of additional users.
1. Review the **Purchase summary** section, which lists the total price for
   all users on the system and a credit for what you've already paid. You are only
   charged for the net change.
1. Enter your payment information.
1. Select **Purchase seats**.

A payment receipt is emailed to you, which you can also access in the Customers Portal under [**Invoices**](https://customers.gitlab.com/invoices).

If your subscription was activated with an activation code, the additional seats are reflected in
your instance immediately. If you're using a license file, you receive an updated file.
To add the seats, [add the license file](../../administration/license_file.md)
to your instance.

## Export your license usage

Prerequisites:

- You must be an administrator.

You can export your license usage into a CSV file.

This file contains the information GitLab uses to manually process
[quarterly reconciliations](../quarterly_reconciliation.md)
or [renewals](#renew-your-subscription). If your instance is firewalled or an
offline environment, you must provide GitLab with this information.

{{< alert type="warning" >}}

Do not open the license usage file. If you open the file, failures might occur when [you submit your license usage data](../../administration/license_file.md#submit-license-usage-data).

{{< /alert >}}

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Subscription**.
1. In the upper-right corner, select **Export license usage file**.

### License usage file contents

The license usage file includes the following information:

- License key
- Licensee email
- License start date (UTC)
- License end date (UTC)
- Company
- Timestamp the file was generated at and exported (UTC)
- Table of historical user counts for each day in the period:
  - Timestamp the count was recorded (UTC)
  - [Billable user](#billable-users) count

{{< alert type="note" >}}

A custom format is used for [dates](https://gitlab.com/gitlab-org/gitlab/blob/3be39f19ac3412c089be28553e6f91b681e5d739/config/initializers/date_time_formats.rb#L7) and [times](https://gitlab.com/gitlab-org/gitlab/blob/3be39f19ac3412c089be28553e6f91b681e5d739/config/initializers/date_time_formats.rb#L13) in CSV files.

{{< /alert >}}

## Renew your subscription

You can [renew your subscription automatically](#automatic-subscription-renewal)
or manually.

You should [renew your subscription manually](#renew-subscription-manually) if
you want to either:

- [Renew for fewer seats](#renew-for-fewer-seats).
- Increase or decrease the quantities of products being renewed.
- Remove add-on products no longer needed for the renewed subscription term.
- Upgrade the subscription tier.

Before your subscription renewal date, you should review your account.

Contact the [support team](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=360000071293) if you need help accessing the Customers Portal or changing the contact person who manages your subscription. Contact the [sales team](https://customers.gitlab.com/contact_us) if you need help renewing your subscription.

### Review your account

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

- [User statistics](../../administration/admin_area.md#users-statistics).
- [Managing users and subscription seats](#manage-users-and-subscription-seats).

### Renew for fewer seats

If you want to renew with fewer seats, you can do either of the following:

- [Manually renew your subscription](#renew-subscription-manually).
- [Cancel your subscription](#enable-or-disable-automatic-subscription-renewal)
  and contact the [Sales team](https://customers.gitlab.com/contact_us) to specify how many seats you need in your subscription going forward.

### Renew subscription manually

15 days before a subscription expires, a banner with the subscription expiry date displays for
administrators in the GitLab user interface.

You cannot manually renew your subscription more than 15 days before the subscription
expires. To check when you can renew:

1. Sign in to the [Customers Portal](https://customers.gitlab.com/customers/sign_in).
1. Select **Subscription actions** ({{< icon name="ellipsis_v" >}}), then select **Renew subscription**
   to view the date you can renew.

To manually renew your subscription:

1. Before the renewal date, [block any inactive or unwanted users](../../administration/moderate_users.md#block-a-user).
1. Determine the number of users you need in the next subscription period.
1. Sign in to the [Customers Portal](https://customers.gitlab.com/customers/sign_in).
1. Under your existing subscription, select **Renew**. This button does not display
   until 15 days before the subscription expires.
1. If renewing Premium or Ultimate products, in the **Seats** text box, enter the
   total number of user seats you'll need for the upcoming year.

   {{< alert type="note" >}}

   Make sure this number is equal to, or greater than
   the number of [billable users](#billable-users) in the system at the time of renewal.

   {{< /alert >}}

1. Optional. If the maximum number of users in your instance exceeded the number
   you were licensed for in the previous subscription term, the
   [overage](../quarterly_reconciliation.md) is due when you renew.

   In the **Users over license** text box, enter the number of
   [users over subscription](#users-over-subscription) for the user overage incurred.
1. Optional. If renewing add-on products, review and update the desired quantity. You can also remove products.
1. Optional. If upgrading the subscription tier, select the desired option.
1. Review your renewal details and select **Renew subscription** to complete the
   payment process.
1. On the [Subscriptions & purchases](https://customers.gitlab.com/subscriptions)
   page on the relevant subscription card, select **Copy activation code** to get
   a copy of the renewal term activation code.
1. [Add the activation code](../../administration/license.md) to your instance.

To add products to your subscription, [contact the sales team](https://customers.gitlab.com/contact_us).

### Automatic subscription renewal

Prerequisites:

- You must have enabled the [synchronization of subscription data](../manage_subscription.md#subscription-data-synchronization).

At least two days before your renewal date, you should [review your account](#review-your-account)
so that your changes synchronize to GitLab in time for your renewal.

When a subscription is set to automatically renew, it renews automatically at
midnight UTC on the expiration date without a gap in available service. Subscriptions
purchased through the Customers Portal are set to automatically renew by default.

The number of user seats is adjusted to fit the [number of billable users in your instance](#view-users)
at the time of renewal, if that number is higher than the current subscription quantity.

#### Email notifications

15 days before a subscription automatically renews, an email is sent with information
about the renewal.

- If your credit card is expired, the email tells you how to update it.
- If you have any outstanding overages or your subscription is not able to automatically
  renew for any other reason, the email tells you to contact our Sales team or
  [manually renew in the Customers Portal](#renew-subscription-manually).
- If there are no issues, the email specifies the:
  - Names and quantity of the products being renewed.
  - Total amount you owe. If your usage increases before renewal, this amount will change.

#### Enable or disable automatic subscription renewal

You can use the Customers Portal to enable or disable automatic subscription renewal:

1. Sign in to the [Customers Portal](https://customers.gitlab.com/customers/sign_in).
   You are taken to the **Subscriptions & purchases** page.
1. Check the subscription card:
   - If the card displays **Expires on DATE**, your subscription is not
     set to automatically renew. To enable automatic renewal, in
     **Subscription actions** ({{< icon name="ellipsis_v" >}}), select **Turn on auto-renew**.
   - If the card displays **Auto-renews on DATE**, your subscription is set to
     automatically renew. To disable automatic renewal:
     1. In **Subscription actions** ({{< icon name="ellipsis_v" >}}), select **Cancel subscription**.
     1. Select a reason for cancelling.
     1. Optional: In **Would you like to add anything?**, enter any relevant information.
     1. Select **Cancel subscription**.

### Manage renewal invoice

An invoice is generated for your renewal. To view or download this renewal invoice,
go to the [Customers Portal invoices page](https://customers.gitlab.com/invoices).

If your account has a [saved credit card](../customers_portal.md#change-your-payment-method),
the card is charged for the invoice amount.

If we are unable to process a payment or the auto-renewal fails for any other reason,
you have 14 days to renew your subscription, after which your GitLab tier is downgraded.

## Add or change the contacts for your subscription

Contacts can manage subscriptions and billing account settings.

For information about how to transfer ownership of the Customers Portal account to another person, see
[Change profile owner information](../customers_portal.md#change-profile-owner-information).

To add another contact for your subscription, see [Add a billing account manager](../customers_portal.md#add-a-billing-account-manager).

## Subscription expiry

Licenses expire at the start of the expiration date, 00:00 server time.

When your license expires, after a 14 day grace period:

- Your instance becomes read-only.
- GitLab locks features, such as Git pushes and issue creation.
- An expiration message is displayed to all administrators.

For example, if a license has an expiry date of January 1, 2025:

- It expires at 11:59:59 PM server time December 31, 2024.
- It is considered expired from 12:00:00 AM server time January 1, 2025.
- The grace period of 14 days starts at 12:00:00 AM server time January 1, 2025
  and ends at 11:59:59 PM server time January 14, 2025.
- Your instance becomes read-only at 12:00:00 AM server time January 15, 2025.

After your license has expired:

- To resume functionality,
  [activate a new license](../../administration/license_file.md).
- To keep using Free tier features only,
  [delete the expired license](../../administration/license_file.md#remove-a-license).

## Storage

The amount of storage and transfer for GitLab Self-Managed instances has no application limits. Administrators are responsible for the underlying infrastructure costs and can set [repository size limits](../../administration/settings/account_and_limit_settings.md#repository-size-limit).
