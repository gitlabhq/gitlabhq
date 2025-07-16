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
called the "true up" process. If you do not do this, your license key does not work.

To view the number of users over subscription, go to the **Admin** area.

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

To increase the number of users covered by your license, [buy seats for your subscription](../manage_users_and_seats.md#buy-more-seats)
during the subscription period. The cost of seats added during the subscription
period is prorated from the date of purchase through to the end of the subscription
period. You can continue to add users even if you reach the number of users in
license count. GitLab [bills you for the overage](../quarterly_reconciliation.md).

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
and [renewals](../manage_subscription.md#renew-subscription). If your instance is firewalled or an
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
  - [Billable user](../manage_users_and_seats.md#billable-users) count

{{< alert type="note" >}}

A custom format is used for [dates](https://gitlab.com/gitlab-org/gitlab/blob/3be39f19ac3412c089be28553e6f91b681e5d739/config/initializers/date_time_formats.rb#L7) and [times](https://gitlab.com/gitlab-org/gitlab/blob/3be39f19ac3412c089be28553e6f91b681e5d739/config/initializers/date_time_formats.rb#L13) in CSV files.

{{< /alert >}}

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

- [User statistics](../../administration/admin_area.md#users-statistics).
- [Managing users and subscription seats](#manage-users-and-subscription-seats).

## Add or change the contacts for your subscription

Contacts can manage subscriptions and billing account settings.

For information about how to transfer ownership of the Customers Portal account to another person, see
[Change profile owner information](../customers_portal.md#change-profile-owner-information).

To add another contact for your subscription, see [Add a billing account manager](../customers_portal.md#add-a-billing-account-manager).

## Storage

The amount of storage and transfer for GitLab Self-Managed instances has no application limits. Administrators are responsible for the underlying infrastructure costs and can set [repository size limits](../../administration/settings/account_and_limit_settings.md#repository-size-limit).
