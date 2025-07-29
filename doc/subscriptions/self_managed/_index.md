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
- [Managing users and subscription seats](../manage_users_and_seats.md#manage-users-and-subscription-seats).

## Add or change the contacts for your subscription

Contacts can manage subscriptions and billing account settings.

For information about how to transfer ownership of the Customers Portal account to another person, see
[Change profile owner information](../customers_portal.md#change-profile-owner-information).

To add another contact for your subscription, see [Add a billing account manager](../customers_portal.md#add-a-billing-account-manager).

## Storage

The amount of storage and transfer for GitLab Self-Managed instances has no application limits. Administrators are responsible for the underlying infrastructure costs and can set [repository size limits](../../administration/settings/account_and_limit_settings.md#repository-size-limit).
