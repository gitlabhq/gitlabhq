---
stage: Fulfillment
group: Purchase
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: index, reference
---

# GitLab self-managed subscription **(PREMIUM SELF)**

You can install, administer, and maintain your own GitLab instance.

This page covers the details of your GitLab self-managed subscription.

GitLab subscription management requires access to the Customers Portal.

## Customers Portal

GitLab provides the [Customers Portal](../index.md#customers-portal) where you can
manage your subscriptions and your account details.

Customers of resellers do not have access to this portal and should contact their reseller for any
changes to their subscription.

## Subscription

The cost of a GitLab self-managed subscription is determined by the following:

- GitLab tier
- Subscription seats

## Choose a GitLab tier

Pricing is [tier-based](https://about.gitlab.com/pricing/), so you can choose
the features that fit your budget. For information on the features available
for each tier, see the
[GitLab self-managed feature comparison](https://about.gitlab.com/pricing/self-managed/feature-comparison/).

## Subscription seats

A GitLab self-managed subscription uses a hybrid model. You pay for a subscription
according to the [maximum number](#maximum-users) of users enabled during the subscription period.
For instances that aren't offline or on a closed network, the maximum number of
simultaneous users in the GitLab self-managed installation is checked each quarter.

If an instance is unable to generate a quarterly usage report, the existing [true-up model](#users-over-license) is used.
Prorated charges are not possible without a quarterly usage report.

### View user totals

You can view users for your license and determine if you've gone over your subscription.

1. On the top bar, select **Menu >** **{admin}** **Admin**.
1. On the left menu, select **Subscription**.

The lists of users are displayed.

#### Billable users

A _billable user_ counts against the number of subscription seats. Every user is considered a
billable user, with the following exceptions:

- [Deactivated users](../../user/admin_area/moderate_users.md#deactivate-a-user) and
  [blocked users](../../user/admin_area/moderate_users.md#block-a-user) don't count as billable users in the current subscription. When they are either deactivated or blocked they release a _billable user_ seat. However, they may
  count toward overages in the subscribed seat count.
- Users who are [pending approval](../../user/admin_area/moderate_users.md#users-pending-approval).
- Members with the Guest role on an Ultimate subscription.
- Users without project or group memberships on an Ultimate subscription.
- GitLab-created service accounts: `Ghost User` and bots
  ([`Support Bot`](../../user/project/service_desk.md#support-bot-user),
  [`Project bot users`](../../user/project/settings/project_access_tokens.md#project-bot-users), and
  so on.)

**Billable users** as reported in the `/admin` section is updated once per day.

#### Maximum users

The number of _maximum users_ reflects the highest number of billable users for the current license period.

#### Users over license

The number of _users over license_ shows how many users are in excess of the number allowed by the license. This number reflects the current license period.

For example, if:

- The license allows 100 users and
- **Maximum users** is 150,

Then this value would be 50.

If the **Maximum users** value is less than or equal to 100, then this value is 0.

A trial license always displays zero for **Users over license**.

If you add more users to your GitLab instance than you are licensed for, payment for the additional users is due [at the time of renewal](../quarterly_reconciliation.md).

If you do not add these users during the renewal process, your license key will not work.

### Tips for managing users and subscription seats

Managing the number of users against the number of subscription seats can be a challenge:

- If LDAP integration is enabled, anyone in the configured domain can sign up for a GitLab account.
  This can result in an unexpected bill at time of renewal.
- If sign-up is enabled on your instance, anyone who can access the instance can sign up for an
  account.

GitLab has several features which can help you manage the number of users:

- Enable the [**Require administrator approval for new sign ups**](../../user/admin_area/settings/sign_up_restrictions.md#require-administrator-approval-for-new-sign-ups)
  option.
- Enable the [User cap](../../user/admin_area/settings/sign_up_restrictions.md#user-cap)
  option. **Available in GitLab 13.7 and later**.
- [Disable new sign-ups](../../user/admin_area/settings/sign_up_restrictions.md), and instead manage new
  users manually.
- View a breakdown of users by role in the [Users statistics](../../user/admin_area/index.md#users-statistics) page.

## Cloud licensing

> Introduced in GitLab 14.1.

Cloud licensing manages licenses for self-managed GitLab subscription plans. Cloud licensing includes:

- Activation: Unlock plan features and activate your self-managed instance by using an activation code.
- License sync: Sync subscription data between your self-managed instance and GitLab.

### What cloud licensing includes

#### Auto-renewals

For renewals that occur on or after 2021-08-01, your subscriptions will auto-renew.
You have the option to manually cancel in the Customers Portal any time until thirty (30) days before renewal.

#### Cloud licensing

You can activate and manage your GitLab licenses by using the Customers Portal.
This feature was formerly known as Seat Link.

#### Operational data

Service data helps GitLab improve the product experience and provide proactive support.
Most data is categorized as optional and can be disabled. Data that is categorized as
operational, like number of issues, pipelines, merge requests, and version, is not configurable.

Please see our [service usage privacy page](https://about.gitlab.com/handbook/legal/privacy/services-usage-data/)
for details on what information is collected.

#### Quarterly subscription reconciliation

See the [quarterly subscription reconciliation section](../quarterly_reconciliation.md) for more information.

### How cloud licensing works

#### Activate your license

1. When you purchase a GitLab self-managed plan, an activation code is generated.
   This activation code is sent to the email address associated with the Customers Portal account.
1. In GitLab, on the top bar, select **Menu >** **{admin}** **Admin**.
1. On the left sidebar, select **Subscription** and paste the activation code in the text field.
1. Select **Activate**.

The page displays the details of the subscription.

#### License sync

Once a day, a job sends license data to the Customers Portal. This information automates activation,
provisioning, co-terms, and renewals. The data is sent securely through an encrypted HTTPS connection
to `customers.gitlab.com` on port `443`.

This sync job runs daily around 3AM UTC. If the job fails, it is retried up to 12 times over approximately 17 hours.

The daily job provides **only** the following information to the Customers Portal:

- Date
- Timestamp
- License key
- Historical maximum user count
- Billable users count
- GitLab version
- Hostname
- Instance ID
- MD5 hash of license

<details>
<summary>Click here to view an example of a cloud licensing sync request.</summary>
<pre><code>
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
  "instance_id": "9367590b-82ad-48cb-9da7-938134c29088",
  "license_md5": "002f02470fe45ef6a333a4282aca6222"
}
</code></pre>
</details>

#### Sync subscription details

You can manually sync your subscription details at any time.

1. On the top bar, select **Menu >** **{admin}** **Admin**.
1. On the left sidebar, select **Subscription**.
1. In the **Subscription details** section, select **Sync subscription details**.

A job is queued. When the job finishes, the subscription details are updated.

#### Troubleshooting cloud licensing sync

If the sync job is not working, ensure you allow network traffic from your GitLab instance
to IP address `104.46.106.135:443` (`customers.gitlab.com`).

## Obtain a subscription

To subscribe to GitLab through a GitLab self-managed installation:

1. Go to the [Customers Portal](https://customers.gitlab.com/) and purchase a GitLab self-managed plan.
1. After purchase, a license file is sent to the email address associated to the Customers Portal account,
   which must be [uploaded to your GitLab instance](../../user/admin_area/license.md#uploading-your-license).

NOTE:
If you're purchasing a subscription for an existing **Free** GitLab self-managed
instance, ensure you're purchasing enough seats to
[cover your users](../../user/admin_area/index.md#administering-users).

## View your subscription

If you are an administrator, you can view the status of your subscription:

1. On the top bar, select **Menu >** **{admin}** **Admin**.
1. On the left sidebar, select **License**.

The **License** page includes the following details:

- Licensee
- Plan
- When it was uploaded, started, and when it expires

It also displays the following important statistics:

| Field              | Description |
|:-------------------|:------------|
| Users in License   | The number of users you've paid for in the current license loaded on the system. The number does not change unless you [add seats](#add-seats-to-a-subscription) during your current subscription period. |
| Billable users     | The daily count of billable users on your system. The count may change as you block or add users to your instance. |
| Maximum users      | The highest number of billable users on your system during the term of the loaded license. |
| Users over license | Calculated as `Maximum users` - `Users in License` for the current license term. This number incurs a retroactive charge that needs to be paid for at renewal. |

## Renew your subscription

To renew your subscription,
[prepare for renewal by reviewing your account](#prepare-for-renewal-by-reviewing-your-account),
then [renew your GitLab self-managed subscription](#renew-a-subscription).

### Prepare for renewal by reviewing your account

The [Customers Portal](https://customers.gitlab.com/customers/sign_in) is your
tool for renewing and modifying your subscription. Before going ahead with renewal,
log in and verify or update:

- The invoice contact details on the **Account details** page.
- The credit card on file on the **Payment Methods** page.

NOTE:
Contact our [support team](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=360000071293)
if you need assistance accessing the Customers Portal or if you need to change
the contact person who manages your subscription.

It's important to regularly review your user accounts, because:

- Stale user accounts that are not blocked count as billable users. You may pay more than you should
  if you renew for too many users.
- Stale user accounts can be a security risk. A regular review helps reduce this risk.

#### Users over License

A GitLab subscription is valid for a specific number of seats. The number of users over license
is the number of _Maximum users_ that exceed the _Users in License_ for the current license term.
You must pay for this number of users either before renewal, or at the time of renewal. This is
known as the _true up_ process.

To view the number of _users over license_ go to the **Admin Area**.

##### Users over license example

You purchase a license for 10 users.

| Event                                              | Billable members | Maximum users |
|:---------------------------------------------------|:-----------------|:--------------|
| Ten users occupy all 10 seats.                     | 10               | 10            |
| Two new users join.                                | 12               | 12            |
| Three users leave and their accounts are removed.  | 9                | 12            |

Users over license = 12 - 10 (Maximum users - users in license)

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

The following items are emailed to you:

- A payment receipt. You can also access this information in the Customers Portal under [**View invoices**](https://customers.gitlab.com/receipts).
- A new license. [Upload this license](../../user/admin_area/license.md#uploading-your-license) to your instance to use it.

### Renew a subscription

Starting 30 days before a subscription expires, GitLab notifies administrators of the date of expiry with a banner in the GitLab user interface.

We recommend following these steps during renewal:

1. Prune any inactive or unwanted users by [blocking them](../../user/admin_area/moderate_users.md#block-a-user).
1. Determine if you have a need for user growth in the upcoming subscription.
1. Log in to the [Customers Portal](https://customers.gitlab.com/customers/sign_in) and select the **Renew** button beneath your existing subscription.

   NOTE:
   If you need to change your [GitLab tier](https://about.gitlab.com/pricing/), contact our sales team via [the sales contact form](https://about.gitlab.com/sales/) for assistance as this can't be done in the Customers Portal.

1. In the first box, enter the total number of user licenses you'll need for the upcoming year. Be sure this number is at least **equal to, or greater than** the number of billable users in the system at the time of performing the renewal.
1. Enter the number of [users over license](#users-over-license) in the second box for the user overage incurred in your previous subscription term.
1. Review your renewal details and complete the payment process.
1. A license for the renewal term is available for download on the [Manage Purchases](https://customers.gitlab.com/subscriptions) page on the relevant subscription card. Select **Copy license to clipboard** or **Download license** to get a copy.
1. [Upload](../../user/admin_area/license.md#uploading-your-license) your new license to your instance.

An invoice is generated for the renewal and available for viewing or download on the [View invoices](https://customers.gitlab.com/receipts) page. If you have difficulty during the renewal process, contact our [support team](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=360000071293) for assistance.

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
- A new license.

[Upload the new license](../../user/admin_area/license.md#uploading-your-license) to your instance.
The new tier takes effect when the new license is uploaded.

## Subscription expiry

When your license expires, GitLab locks down features, like Git pushes
and issue creation. Then, your instance becomes read-only and
an expiration message is displayed to all administrators.

For GitLab self-managed instances, you have a 14-day grace period
before this occurs.

- To resume functionality, upload a new license.
- To fall back to Free features, delete the expired license.

## Contact Support

Learn more about:

- The tiers of [GitLab Support](https://about.gitlab.com/support/).
- [Submit a request via the Support Portal](https://support.gitlab.com/hc/en-us/requests/new).

We also encourage all users to search our project trackers for known issues and
existing feature requests in the [GitLab](https://gitlab.com/gitlab-org/gitlab/-/issues/) project.

These issues are the best avenue for getting updates on specific product plans
and for communicating directly with the relevant GitLab team members.

## Troubleshooting

### Credit card declined

If your credit card is declined when purchasing a GitLab subscription, possible reasons include:

- The credit card details provided are incorrect.
- The credit card account has insufficient funds.
- You are using a virtual credit card and it has insufficient funds, or has expired.
- The transaction exceeds the credit limit.
- The transaction exceeds the credit card's maximum transaction amount.

Check with your financial institution to confirm if any of these reasons apply. If they don't
apply, contact [GitLab Support](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=360000071293).
