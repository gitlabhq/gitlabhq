---
stage: Fulfillment
group: Purchase
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
type: index, reference
---

# GitLab self-managed subscription **(PREMIUM SELF)**

After you subscribe to GitLab, you can manage the details of your self-managed subscription.

## Obtain a self-managed subscription

To subscribe to GitLab for a GitLab self-managed installation:

1. Go to the [Customers Portal](https://customers.gitlab.com/) and purchase a GitLab self-managed plan.
1. After purchase, an activation code is sent to the email address associated with the Customers Portal account.
   You must [add this code to your GitLab instance](../../user/admin_area/license.md).

NOTE:
If you're purchasing a subscription for an existing **Free** GitLab self-managed
instance, ensure you're purchasing enough seats to
[cover your users](../../user/admin_area/index.md#administering-users).

### Subscription seats

A GitLab self-managed subscription uses a hybrid model. You pay for a subscription
according to the [maximum number](#maximum-users) of users enabled during the subscription period.
For instances that aren't offline or on a closed network, the maximum number of
simultaneous users in the GitLab self-managed installation is checked each quarter.

If an instance is unable to generate a quarterly usage report, the existing [true up model](#users-over-subscription) is used.
Prorated charges are not possible without a quarterly usage report.

## View user totals

You can view users for your license and determine if you've gone over your subscription.

1. On the top bar, select **Main menu > Admin**.
1. On the left menu, select **Subscription**.

The lists of users are displayed.

### Billable users

A _billable user_ counts against the number of subscription seats. Every user is considered a
billable user, with the following exceptions:

- [Deactivated users](../../user/admin_area/moderate_users.md#deactivate-a-user) and
  [blocked users](../../user/admin_area/moderate_users.md#block-a-user) don't count as billable users in the current subscription. When they are either deactivated or blocked they release a _billable user_ seat. However, they may
  count toward overages in the subscribed seat count.
- Users who are [pending approval](../../user/admin_area/moderate_users.md#users-pending-approval).
- Users with only the [Minimal Access role](../../user/permissions.md#users-with-minimal-access) on self-managed Ultimate subscriptions or any GitLab.com subscriptions.
- Users with only the [Guest or Minimal Access roles on an Ultimate subscription](#free-guest-users).
- Users without project or group memberships on an Ultimate subscription.
- GitLab-created service accounts:
  - [Ghost User](../../user/profile/account/delete_account.md#associated-records).
  - Bots such as:
    - [Support Bot](../../user/project/service_desk.md#support-bot-user).
    - [Bot users for projects](../../user/project/settings/project_access_tokens.md#bot-users-for-projects).
    - [Bot users for groups](../../user/group/settings/group_access_tokens.md#bot-users-for-groups).
    - Other [internal users](../../development/internal_users.md#internal-users).

**Billable users** as reported in the `/admin` section is updated once per day.

### Maximum users

The number of _maximum users_ reflects the highest number of billable users for the current license period.

### Users over subscription

The number of _users over subscription_ shows how many users are in excess of the number allowed by the subscription. This number reflects the current subscription period.

For example, if:

- The subscription allows 100 users and
- **Maximum users** is 150,

Then this value would be 50.

If the **Maximum users** value is less than or equal to 100, then this value is 0.

A trial license always displays zero for **Users over subscription**.

If you add more users to your GitLab instance than you are licensed for, payment for the additional users is due [at the time of renewal](../quarterly_reconciliation.md).

If you do not add these users during the renewal process, your license key will not work.

### Free Guest users **(ULTIMATE)**

In the **Ultimate** tier, users who are assigned the Guest role do not consume a seat.
The user must not be assigned any other role, anywhere in the instance.

- If your project is private or internal, a user with the Guest role has
  [a set of permissions](../../user/permissions.md#project-members-permissions).
- If your project is public, all users, including those with the Guest role
  can access your project.
- A user's highest assigned role is updated asynchronously and may take some time to update.

NOTE:
If a user creates a project, they are assigned the Maintainer or Owner role.
To prevent a user from creating projects, as an administrator, you can mark the user
as [external](../../user/admin_area/external_users.md).

## Tips for managing users and subscription seats

Managing the number of users against the number of subscription seats can be a challenge:

- If LDAP integration is enabled, anyone in the configured domain can sign up for a GitLab account.
  This can result in an unexpected bill at time of renewal.
- If sign-up is enabled on your instance, anyone who can access the instance can sign up for an
  account.

GitLab has several features which can help you manage the number of users:

- Enable the [**Require administrator approval for new sign ups**](../../user/admin_area/settings/sign_up_restrictions.md#require-administrator-approval-for-new-sign-ups)
  option.
- Enable `block_auto_created_users` for new sign-ups via [LDAP](../../administration/auth/ldap/index.md#basic-configuration-settings) or [OmniAuth](../../integration/omniauth.md#configure-common-settings).
- Enable the [User cap](../../user/admin_area/settings/sign_up_restrictions.md#user-cap)
  option. **Available in GitLab 13.7 and later**.
- [Disable new sign-ups](../../user/admin_area/settings/sign_up_restrictions.md), and instead manage new
  users manually.
- View a breakdown of users by role in the [Users statistics](../../user/admin_area/index.md#users-statistics) page.

## Subscription data synchronization

> Introduced in GitLab 14.1.

Subscription data can be automatically synchronized between your self-managed instance and GitLab.
To enable subscription data synchronization you must have:

- GitLab Enterprise Edition (EE), version 14.1 or later.
- Connection to the internet, and must not have an offline environment.
- [Activated](../../user/admin_area/license.md) your instance with an activation code.

When your instance is activated, and data is synchronized, the following processes are automated:

- [Quarterly subscription reconciliation](../quarterly_reconciliation.md).
- Subscription renewals.
- Subscription updates, such as adding more seats or upgrading a GitLab tier.

At approximately 03:00 UTC, a daily synchronization job sends subscription data to the Customers
Portal. For this reason, updates and renewals may not apply immediately.

The data is sent securely through an encrypted HTTPS connection to `customers.gitlab.com` on port
`443`. If the job fails, it retries up to 12 times over approximately 17 hours.

### Subscription data

The daily synchronization job sends **only** the following information to the Customers Portal:

- Date
- Timestamp
- License key
  - Company name (encrypted within license key)
  - Licensee name (encrypted within license key)
  - Licensee email (encrypted within license key)
- Historical maximum user count
- Billable users count
- GitLab version
- Hostname
- Instance ID

Example of a license sync request:

```json
{
  "gitlab_version": "14.1.0-pre",
  "timestamp": "2021-06-14T12:00:09Z",
  "date": "2021-06-14",
  "license_key": "eyJkYXRhIjoiYlR2MFBPSEJPSnNOc1plbGtFRGZ6M
  Ex1mWWhyM1Y3NWFOU0Zj\nak1xTmtLZHU1YzJJUWJzZzVxT3FQRU1PXG5
  KRzErL2ZNd0JuKzBwZmQ3YnY4\nTkFrTDFsMFZyQi9NcG5DVEdkTXQyNT
  R3NlR0ZEc0MjBoTTVna2VORlVcbjAz\nbUgrNGl5N0NuenRhZlljd096R
  nUzd2JIWEZ3NzV2V2lqb3FuQ3RYZWppWVFU\neDdESkgwSUIybFJhZlxu
  Y2k0Mzl3RWlKYjltMkJoUzExeGIwWjN3Uk90ZGp1\nNXNNT3dtL0Vtc3l
  zWVowSHE3ekFILzBjZ2FXSXVQXG5ENWJwcHhOZzRlcFhr\neFg0K3d6Zk
  w3cHRQTTJMTGdGb2Vwai90S0VJL0ZleXhxTEhvaUc2NzVIbHRp\nVlRcb
  nYzY090bmhsdTMrc0VGZURJQ3VmcXFFUS9ISVBqUXRhL3ZTbW9SeUNh\n
  SjdDTkU4YVJnQTlBMEF5OFBiZlxuT0VORWY5WENQVkREdUMvTTVCb25Re
  ENv\nK0FrekFEWWJ6VGZLZ1dBRjgzUXhyelJWUVJGTTErWm9TeTQ4XG5V
  aWdXV0d4\nQ2graGtoSXQ1eXdTaUFaQzBtZGd2aG1YMnl1KzltcU9WMUx
  RWXE4a2VSOHVn\nV3BMN1VFNThcbnMvU3BtTk1JZk5YUHhOSmFlVHZqUz
  lXdjlqMVZ6ODFQQnFx\nL1phaTd6MFBpdG5NREFOVnpPK3h4TE5CQ1xub
  GtacHNRdUxTZmtWWEZVUnB3\nWTZtWGdhWE5GdXhURjFndWhyVDRlTE92
  bTR3bW1ac0pCQnBkVWJIRGNyXG5z\nUjVsTWJxZEVUTXJNRXNDdUlWVlZ
  CTnJZVTA2M2dHblc4eVNXZTc0enFUcW1V\nNDBrMUZpN3RTdzBaZjBcbm
  16UGNYV0RoelpkVk02cWR1dTl0Q1VqU05tWWlU\nOXlwRGZFaEhXZWhjb
  m50RzA5UWVjWEM5em52Y1BjU1xueFU0MDMvVml5R3du\nQXNMTHkyajN5
  b3hhTkJUSWpWQ1BMUjdGeThRSEVnNGdBd0x6RkRHVWg1M0Qz\nMHFRXG5
  5eWtXdHNHN3VBREdCNmhPODFJanNSZnEreDhyb2ZpVU5JVXo4NCtD\nem
  Z1V1Q0K1l1VndPTngyc1l0TU5cbi9WTzlaaVdPMFhtMkZzM2g1NlVXcGI
  y\nSUQzRnRlbW5vZHdLOWU4L0tiYWRESVRPQmgzQnIxbDNTS2tHN1xuQ3
  hpc29D\nNGh4UW5mUmJFSmVoQkh6eHV1dkY5aG11SUsyVmVDQm1zTXZCY
  nZQNGdDbHZL\ndUExWnBEREpDXG41eEhEclFUd3E1clRYS2VuTjhkd3BU
  SnVLQXgvUjlQVGpy\ncHJLNEIzdGNMK0xIN2JKcmhDOTlabnAvLzZcblZ
  HbXk5SzJSZERIcXp3U2c3\nQjFwSmFPcFBFUHhOUFJxOUtnY2hVR0xWMF
  d0Rk9vPVxuIiwia2V5IjoiUURM\nNU5paUdoRlVwZzkwNC9lQWg5bFY0Q
  3pkc2tSQjBDeXJUbG1ZNDE2eEpPUzdM\nVXkrYXRhTFdpb0lTXG5sTWlR
  WEU3MVY4djFJaENnZHJGTzJsTUpHbUR5VHY0\ndWlSc1FobXZVWEhpL3h
  vb1J4bW9XbzlxK2Z1OGFcblB6anp1TExhTEdUQVdJ\nUDA5Z28zY3JCcz
  ZGOEVLV28xVzRGWWtUUVh2TzM0STlOSjVHR1RUeXkzVkRB\nc1xubUdRe
  jA2eCtNNkFBM1VxTUJLZXRMUXRuNUN2R3l3T1VkbUx0eXZNQ3JX\nSWVQ
  TElrZkJwZHhPOUN5Z1dCXG44UkpBdjRSQ1dkMlFhWVdKVmxUMllRTXc5\
  nL29LL2hFNWRQZ1pLdWEyVVZNRWMwRkNlZzg5UFZrQS9mdDVcbmlETWlh
  YUZz\nakRVTUl5SjZSQjlHT2ovZUdTRTU5NVBBMExKcFFiVzFvZz09XG4
  iLCJpdiI6\nImRGSjl0YXlZWit2OGlzbGgyS2ZxYWc9PVxuIn0=\n",
  "max_historical_user_count": 75,
  "billable_users_count": 75,
  "hostname": "gitlab.example.com",
  "instance_id": "9367590b-82ad-48cb-9da7-938134c29088"
}
```

### Manually synchronize your subscription details

You can manually synchronize your subscription details at any time.

1. On the top bar, select **Main menu > Admin**.
1. On the left sidebar, select **Subscription**.
1. In the **Subscription details** section, select **Sync subscription details**.

A job is queued. When the job finishes, the subscription details are updated.

## View your subscription

If you are an administrator, you can view the status of your subscription:

1. On the top bar, select **Main menu > Admin**.
1. On the left sidebar, select **Subscription**.

The **Subscription** page includes the following details:

- Licensee
- Plan
- When it was uploaded, started, and when it expires

It also displays the following information:

| Field              | Description |
|:-------------------|:------------|
| Users in License   | The number of users you've paid for in the current license loaded on the system. The number does not change unless you [add seats](#add-seats-to-a-subscription) during your current subscription period. |
| Billable users     | The daily count of billable users on your system. The count may change as you block, deactivate, or add users to your instance. |
| Maximum users      | The highest number of billable users on your system during the term of the loaded license. |
| Users over subscription | Calculated as `Maximum users` - `Users in subscription` for the current license term. This number incurs a retroactive charge that must be paid before renewal. |

## Export your license usage

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/66826) in GitLab 14.2.

If you are an administrator, you can export your license usage into a CSV:

1. On the top bar, select **Main menu > Admin**.
1. On the left sidebar, select **Subscription**.
1. In the upper-right corner, select **Export license usage file**.

This file contains the information GitLab uses to manually process quarterly reconciliations or renewals. If your instance is firewalled or an offline environment, you must provide GitLab with this information.

The **License Usage** CSV includes the following details:

- License key
- Licensee email
- License start date
- License end date
- Company
- Generated at (the timestamp for when the file was exported)
- Table of historical user counts for each day in the period:
  - Timestamp the count was recorded
  - Billable user count

NOTES:

- All date timestamps are displayed in UTC.
- A custom format is used for [dates](https://gitlab.com/gitlab-org/gitlab/blob/3be39f19ac3412c089be28553e6f91b681e5d739/config/initializers/date_time_formats.rb#L7) and [times](https://gitlab.com/gitlab-org/gitlab/blob/3be39f19ac3412c089be28553e6f91b681e5d739/config/initializers/date_time_formats.rb#L13) in CSV files.

## Renew your subscription

You can renew your subscription starting from 15 days before your subscription expires. To renew your subscription:

1. [Prepare for renewal by reviewing your account.](#prepare-for-renewal-by-reviewing-your-account)
1. [Renew your GitLab self-managed subscription.](#renew-subscription-manually)

### Prepare for renewal by reviewing your account

The [Customers Portal](https://customers.gitlab.com/customers/sign_in) is your
tool for renewing and modifying your subscription. Before going ahead with renewal,
sign in and verify or update:

- The invoice contact details on the **Account details** page.
- The credit card on file on the **Payment Methods** page.

NOTE:
Contact our [support team](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=360000071293)
if you need assistance accessing the Customers Portal or if you need to change
the contact person who manages your subscription.

It's important to regularly review your user accounts, because:

- Stale user accounts may count as billable users. You may pay more than you should
  if you renew for too many users.
- Stale user accounts can be a security risk. A regular review helps reduce this risk.

#### Users over subscription

A GitLab subscription is valid for a specific number of seats. The number of users over subscription
is the number of _maximum users_ that exceed the users in subscription for the current subscription term.
You must pay for this number of users either before renewal, or at the time of renewal. This is
called the _true up_ process.

To view the number of users over subscription go to the **Admin Area**.

##### Users over subscription example

You purchase a subscription for 10 users.

| Event                                              | Billable users | Maximum users |
|:---------------------------------------------------|:-----------------|:--------------|
| Ten users occupy all 10 seats.                     | 10               | 10            |
| Two new users join.                                | 12               | 12            |
| Three users leave and their accounts are removed.  | 9                | 12            |

Users over subscription = 12 - 10 (Maximum users - users in license)

### Add seats to a subscription

The users in license count can be increased by adding seats to a subscription any time during the
subscription period. The cost of seats added during the subscription
period is prorated from the date of purchase through the end of the subscription period.

To add seats to a subscription:

1. Log in to the [Customers Portal](https://customers.gitlab.com/).
1. Navigate to the **Manage Purchases** page.
1. Select **Add more seats** on the relevant subscription card.
1. Enter the number of additional users.
1. Select **Proceed to checkout**.
1. Review the **Subscription Upgrade Detail**. The system lists the total price for all users on the system and a credit for what you've already paid. You are only be charged for the net change.
1. Select **Confirm Upgrade**.

A payment receipt is emailed to you, which you can also access in the Customers Portal under [**View invoices**](https://customers.gitlab.com/receipts).

If your subscription was activated with an activation code, the additional seats are reflected in
your instance immediately. If you're using a license file, you receive an updated file.
To add the seats, [add the license file](../../user/admin_area/license_file.md)
to your instance.

### Renew subscription manually

Starting 30 days before a subscription expires, a banner with the expiry date displays for administrators in the GitLab user interface.

You should follow these steps during renewal:

1. Prior to the renewal date, prune any inactive or unwanted users by [blocking them](../../user/admin_area/moderate_users.md#block-a-user).
1. Determine if you have a need for user growth in the upcoming subscription.
1. Log in to the [Customers Portal](https://customers.gitlab.com/customers/sign_in) and select the **Renew** button beneath your existing subscription.
The **Renew** button remains disabled (grayed-out) until 15 days before a subscription expires.
You can hover your mouse on the **Renew** button to see the date when it will become active.

   NOTE:
   If you need to change your [GitLab tier](https://about.gitlab.com/pricing/), contact our sales team with [the sales contact form](https://about.gitlab.com/sales/) for assistance as this can't be done in the Customers Portal.

1. In the first box, enter the total number of user licenses you'll need for the upcoming year. Be sure this number is at least **equal to, or greater than** the number of billable users in the system at the time of performing the renewal.
1. Enter the number of [users over subscription](#users-over-subscription) in the second box for the user overage incurred in your previous subscription term.
1. Review your renewal details and complete the payment process.
1. An activation code for the renewal term is available on the [Manage Purchases](https://customers.gitlab.com/subscriptions) page on the relevant subscription card. Select **Copy activation code** to get a copy.
1. [Add the activation code](../../user/admin_area/license.md) to your instance.

An invoice is generated for the renewal and available for viewing or download on the [View invoices](https://customers.gitlab.com/receipts) page. If you have difficulty during the renewal process, contact our [support team](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=360000071293) for assistance.

### Automatic subscription renewal

When a subscription is set to auto-renew, it renews automatically on the
expiration date (at midnight UTC) without a gap in available service. Subscriptions purchased through Customers Portal are set to auto-renew by default.
The number of user licenses is adjusted to fit the [number of billable users in your instance](#view-user-totals) at the time of renewal.
Before auto-renewal you should [prepare for the renewal](#prepare-for-renewal-by-reviewing-your-account) at least 2 days before the renewal date, so that your changes synchronize to GitLab in time for your renewal. To auto-renew your subscription,
you must have enabled the [synchronization of subscription data](#subscription-data-synchronization).

You can view and download your renewal invoice on the Customers Portal
[View invoices](https://customers.gitlab.com/receipts) page. If your account has a [saved credit card](../customers_portal.md#change-your-payment-method), the card is charged for the invoice amount. If we are unable to process a payment or the auto-renewal fails for any other reason, you have 14 days to renew your subscription, after which your GitLab tier is downgraded.

#### Email notifications

15 days before a subscription automatically renews, an email is sent with information about the renewal.

- If your credit card is expired, the email tells you how to update it.
- If you have any outstanding overages or subscription isn't able to auto-renew for any other reason, the email tells you to contact our Sales team or [renew in Customers Portal](#renew-subscription-manually).
- If there are no issues, the email specifies the names and quantity of the products being renewed. The email also includes the total amount you owe. If your usage increases or decreases before renewal, this amount can change.

#### Enable or disable automatic subscription renewal

To view or change automatic subscription renewal (at the same tier as the
previous period), sign in to the [Customers Portal](https://customers.gitlab.com/customers/sign_in), and:

- If a **Turn on auto-renew** button is displayed, your subscription was canceled
  previously. Select it to resume automatic renewal.
- If a **Cancel subscription** button is displayed, your subscription is set to automatically
  renew at the end of the subscription period. Select it to cancel automatic renewal.

If you have difficulty during the renewal process, contact the
[Support team](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=360000071293) for assistance.

## Upgrade your subscription tier

To upgrade your [GitLab tier](https://about.gitlab.com/pricing/):

1. Log in to the [Customers Portal](https://customers.gitlab.com/customers/sign_in).
1. Select the **Upgrade** button on the relevant subscription card on the
   [Manage purchases](https://customers.gitlab.com/subscriptions) page.
1. Select the desired upgrade.
1. Confirm the active form of payment, or add a new form of payment.
1. Select the **I accept the Privacy Policy and Terms of Service** checkbox.
1. Select **Purchase**.

The following is emailed to you:

- A payment receipt. You can also access this information in the Customers Portal under
  [**View invoices**](https://customers.gitlab.com/receipts).
- A new activation code for your license.

[Add the activation code](../../user/admin_area/license.md) to your instance.
The new tier takes effect when the new license is activated.

## Add or change the contacts for your subscription

Contacts can renew a subscription, cancel a subscription, or transfer the subscription to a different namespace.

To change the contacts:

1. Ensure an account exists in the
   [Customers Portal](https://customers.gitlab.com/customers/sign_in) for the user you want to add.
1. Verify you have access to at least one of
   [these requirements](https://about.gitlab.com/handbook/support/license-and-renewals/workflows/customersdot/associating_purchases.html).
1. [Create a ticket with the Support team](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=360000071293). Include any relevant material in your request.

## Subscription expiry

When your license expires, GitLab locks down features, like Git pushes
and issue creation. Then, your instance becomes read-only and
an expiration message is displayed to all administrators.

For GitLab self-managed instances, you have a 14-day grace period
before this occurs.

- To resume functionality, activate a new license.
- To fall back to Free features, delete the expired license.

## Activate a license file or key

If you have a license file or key, you can activate it [in the Admin Area](../../user/admin_area/license_file.md#activate-gitlab-ee-with-a-license-file-or-key).

## Contact Support

- See the tiers of [GitLab Support](https://about.gitlab.com/support/).
- [Submit a request](https://support.gitlab.com/hc/en-us/requests/new) through the Support Portal.

We also encourage all users to search our project trackers for known issues and
existing feature requests in the [GitLab](https://gitlab.com/gitlab-org/gitlab/-/issues/) project.

These issues are the best avenue for getting updates on specific product plans
and for communicating directly with the relevant GitLab team members.

## Troubleshooting

### Subscription data fails to synchronize

If the synchronization job is not working, ensure you allow network traffic from your GitLab
instance to IP addresses `172.64.146.11:443` and `104.18.41.245:443` (`customers.gitlab.com`).

### Credit card declined

If your credit card is declined when purchasing a GitLab subscription, possible reasons include:

- The credit card details provided are incorrect.
- The credit card account has insufficient funds.
- You are using a virtual credit card and it has insufficient funds, or has expired.
- The transaction exceeds the credit limit.
- The transaction exceeds the credit card's maximum transaction amount.

Check with your financial institution to confirm if any of these reasons apply. If they don't
apply, contact [GitLab Support](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=360000071293).

### Check daily and historical billable users

Administrators can get a list of daily and historical billable users in your GitLab instance.

1. [Start a Rails console session](../../administration/operations/rails_console.md#starting-a-rails-console-session).
1. Count the number of users in the instance:

   ```ruby
   User.billable.count
   ```

1. Get the historical maximum number of users on the instance from the past year:

   ```ruby
   ::HistoricalData.max_historical_user_count(from: 1.year.ago.beginning_of_day, to: Time.current.end_of_day)
   ```

### Update daily billable and historical users

Administrators can trigger a manual update of the daily and historical billable users in your GitLab instance.

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
