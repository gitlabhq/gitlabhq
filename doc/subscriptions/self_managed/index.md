---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: index, reference
---

# GitLab self-managed subscription **(STARTER ONLY)**

You can install, administer, and maintain your own GitLab instance.

This page covers the details of your GitLab self-managed subscription.

## Subscription

The cost of a GitLab self-managed subscription is determined by the following:

- GitLab tier
- Subscription seats

## GitLab tier

Pricing is [tier-based](https://about.gitlab.com/pricing/), allowing you to choose
the features which fit your budget. For information on what features are available
at each tier, see the
[GitLab self-managed feature comparison](https://about.gitlab.com/pricing/self-managed/feature-comparison/).

## Subscription seats

A self-managed subscription uses a hybrid model. You pay for a subscription
according to the maximum number of users enabled during the subscription period.
For instances that aren't offline or on a closed network, the maximum number of
simultaneous users in the self-managed installation is checked each quarter,
using [Seat Link](#seat-link).

### Billable users

A _billable user_ counts against the number of subscription seats. Every user is considered a
billable user, with the following exceptions:

- [Deactivated users](../../user/admin_area/activating_deactivating_users.md#deactivating-a-user) and
  [blocked users](../../user/admin_area/blocking_unblocking_users.md) don't count as billable users in the current subscription. When they are either deactivated or blocked they release a _billable user_ seat. However, they may
  count toward overages in the subscribed seat count.
- Users who are [pending approval](../../user/admin_area/approving_users.md).
- Members with Guest permissions on an Ultimate subscription.
- GitLab-created service accounts: `Ghost User` and bots (`Support Bot`, [`Project bot users`](../../user/project/settings/project_access_tokens.md#project-bot-users), and so on).

### Users statistics

To view a breakdown of the users within your instance, including active, billable,
and blocked, go to **Admin Area > Overview > Dashboard** and select **Users statistics**
in the **Users** section. For more details, see
[Users statistics](../../user/admin_area/index.md#users-statistics).

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
  option. **Available in GitLab 13.6 and later**.
- [Disable new sign-ups](../../user/admin_area/settings/sign_up_restrictions.md), and instead manage new
  users manually.

## Obtain a subscription

To subscribe to GitLab through a self-managed installation:

1. Go to the [Customers Portal](https://customers.gitlab.com/) and purchase a
   **Starter**, **Premium**, or **Ultimate** self-managed plan.
1. After purchase, a license file is sent to the email address associated to the Customers Portal account,
   which must be [uploaded to your GitLab instance](../../user/admin_area/license.md#uploading-your-license).

TIP: **Tip:**
If you're purchasing a subscription for an existing **Core** self-managed
instance, ensure you're purchasing enough seats to
[cover your users](../../user/admin_area/index.md#administering-users).

## View your subscription

If you are an administrator, to view the status of your self-managed subscription,
log in to the your GitLab instance and go to the **License** page:

1. Go to **Admin Area**.
1. From the left-hand menu, select **License**.

Read more about the [license admin area](../../user/admin_area/license.md).

## Renew your subscription

To renew your subscription,
[prepare for renewal by reviewing your account](#prepare-for-renewal-by-reviewing-your-account),
then [renew your self-managed subscription](#renew-a-subscription).

### Prepare for renewal by reviewing your account

The [Customers Portal](https://customers.gitlab.com/customers/sign_in) is your
tool for renewing and modifying your subscription. Before going ahead with renewal,
log in and verify or update:

- The invoice contact details on the **Account details** page.
- The credit card on file on the **Payment Methods** page.

TIP: **Tip:**
Contact our [support team](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=360000071293)
if you need assistance accessing the Customers Portal or if you need to change
the contact person who manages your subscription.

It's important to regularly review your user accounts, because:

- A GitLab subscription is based on the number of users. You pay more than
  you should if you renew for too many users, while the renewal fail if you
  attempt to renew a subscription for too few users.
- Stale user accounts can be a security risk. A regular review helps reduce this risk.

#### Users over License

A GitLab subscription is valid for a specific number of users. For details, see
[Billable users](#billable-users). If the billable user
count exceeds the number included in the subscription, known as the number of
_users over license_, you must pay for the excess number of users either before
renewal, or at the time of renewal. This is also known as the _true up_ process.

Self-managed instances can add users to a subscription any time during the
subscription period. The cost of additional users added during the subscription
period is prorated from the date of purchase through the end of the subscription period.

To add users to a subscription:

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

1. Prune any inactive or unwanted users by [blocking them](../../user/admin_area/blocking_unblocking_users.md#blocking-a-user).
1. Determine if you have a need for user growth in the upcoming subscription.
1. Log in to the [Customers Portal](https://customers.gitlab.com/customers/sign_in) and select the **Renew** button beneath your existing subscription.

   TIP: **Tip:**
   If you need to change your [GitLab tier](https://about.gitlab.com/pricing/), contact our sales team via `renewals@gitlab.com` for assistance as this can't be done in the Customers Portal.

1. In the first box, enter the total number of user licenses you’ll need for the upcoming year. Be sure this number is at least **equal to, or greater than** the number of billable users in the system at the time of performing the renewal.
1. Enter the number of [users over license](#users-over-license) in the second box for the user overage incurred in your previous subscription term.

   TIP: **Tip:**
   You can find the _users over license_ in your instance's **Admin** dashboard by clicking on the **Admin Area** in the top bar, or navigating to `/admin`.

   The following table describes details of your admin dashboard and renewal terms:

   | Field | Description |
   |:------|:------------|
   | Users in License | The number of users you've paid for in the current license loaded on the system. This does not include the amount you've paid for `Users over license` during renewal. |
   | Billable users | The daily count of billable users on your system. |
   | Maximum users | The highest number of billable users on your system during the term of the loaded license. If this number exceeds your users in license count at any point, you incur users over license. |
   | Users over license | The number of users that exceed the `Users in License` for the current license term. Charges for this number of users are incurred at the next renewal. |

1. Review your renewal details and complete the payment process.
1. A license for the renewal term is available for download on the [Manage Purchases](https://customers.gitlab.com/subscriptions) page on the relevant subscription card. Select **Copy license to clipboard** or **Download license** to get a copy.
1. [Upload](../../user/admin_area/license.md#uploading-your-license) your new license to your instance.

An invoice is generated for the renewal and available for viewing or download on the [View invoices](https://customers.gitlab.com/receipts) page. If you have difficulty during the renewal process, contact our [support team](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=360000071293) for assistance.

### Seat Link

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/208832) in [GitLab Starter](https://about.gitlab.com/pricing/) 12.9.

Seat Link allows GitLab Inc. to provide our self-managed customers with prorated charges for user growth throughout the year using a quarterly reconciliation process.

Seat Link daily sends a count of all users in connected self-managed instances to GitLab. That information is used to automate prorated reconciliations. The data is sent securely through an encrypted HTTPS connection.

Seat Link provides **only** the following information to GitLab:

- Date
- License key
- Historical maximum user count
- Billable users count

For offline or closed network customers, the existing [true-up model](#users-over-license) is used. Prorated charges are not possible without user count data.

<details>
<summary>Click here to view example content of a Seat Link POST request.</summary>

<pre><code>
{
  date: '2020-01-29',
  license_key: 'ZXlKa1lYUmhJam9pWm5WNmVsTjVZekZ2YTJoV2NucDBh
RXRxTTA5amQxcG1VMVZqDQpXR3RwZEc5SGIyMVhibmxuZDJ0NWFrNXJTVzVH
UzFCT1hHNVRiVFIyT0ZaUFlVSm1OV1ZGV0VObE1uVk4NCk4xY3ZkM1F4Y2to
MFFuVklXSFJvUWpSM01VdE9SVE5rYkVjclZrdDJORkpOTlhka01qaE5aalpj
YmxSMg0KWVd3MFNFTldTRmRtV1ZGSGRDOUhPR05oUVZvNUsxVnRXRUZIZFU1
U1VqUm5aVFZGZUdwTWIxbDFZV1EyDQphV1JTY1V4c1ZYSjNPVGhrYVZ4dVlu
TkpWMHRJZUU5dmF6ZEJRVVkxTlVWdFUwMTNSMGRHWm5SNlJFcFYNClQyVkJl
VXc0UzA0NWFFb3ZlSFJrZW0xbVRqUlZabkZ4U1hWcWNXRnZYRzVaTm5GSmVW
UnJVR1JQYTJKdA0KU0ZZclRHTmFPRTVhZEVKMUt6UjRkSE15WkRCT1UyNWlS
MGRJZDFCdmRFWk5Za2h4Tm5sT1VsSktlVlYyDQpXRmhjYmxSeU4wRnRNMU5q
THpCVWFGTmpTMnh3UWpOWVkyc3pkbXBST1dnelZHY3hUV3hxVDIwdlZYRlQN
Ck9EWTJSVWx4WlVOT01EQXhVRlZ3ZGs1Rk0xeHVSVEJTTDFkMWJUQTVhV1ZK
WjBORFdWUktaRXNyVnpsTw0KTldkWWQwWTNZa05VWlZBMmRUVk9kVUpxT1hV
Mk5VdDFTUzk0TUU5V05XbFJhWGh0WEc1cVkyWnhaeTlXDQpTMEpyZWt0cmVY
bzBOVGhFVG1oU1oxSm5WRFprY0Uwck0wZEdhVUpEV1d4a1RXZFRjVU5tYTB0
a2RteEQNCmNWTlFSbFpuWlZWY2JpdFVVbXhIV0d4MFRuUnRWbkJKTkhwSFJt
TnRaMGsyV0U1MFFUUXJWMUJVTWtOSA0KTVhKUWVGTkxPVTkzV1VsMlVUUldk
R3hNTWswNU1USlNjRnh1U1UxTGJTdHRRM1l5YTFWaWJtSlBTMkUxDQplRkpL
SzJSckszaG1hVXB1ZVRWT1UwdHZXV0ZOVG1WamMyVjRPV0pSUlZkUU9UUnpU
VWh2Wlc5cFhHNUgNClNtRkdVMDUyY1RGMWNGTnhVbU5JUkZkeGVWcHVRMnBh
VTBSUGR6VnRNVGhvWTFBM00zVkZlVzFOU0djMA0KY1ZFM1FWSlplSFZ5UzFS
aGIxTmNia3BSUFQxY2JpSXNJbxRsZVNJNkltZFhiVzFGVkRZNWNFWndiV2Rt
DQpNWEIyY21SbFFrdFNZamxaYURCdVVHcHhiRlV3Tm1WQ2JGSlFaSFJ3Y0Rs
cFMybGhSMnRPTkZOMWNVNU0NClVGeHVTa3N6TUUxcldVOTVWREl6WVVWdk5U
ZGhWM1ZvVjJkSFRtZFBZVXRJTkVGcE55dE1NRE5dWnpWeQ0KWlV0aWJsVk9T
RmRzVVROUGRHVXdWR3hEWEc1MWjWaEtRMGQ2YTAxWFpUZHJURTVET0doV00w
ODRWM0V2DQphV2M1YWs5cWFFWk9aR3BYTm1aVmJXNUNaazlXVUVRMWRrMXpj
bTFDV0V4dldtRmNibFpTTWpWU05VeFMNClEwTjRNMWxWCUtSVGEzTTJaV2xE
V0hKTFRGQmpURXRsZFVaQlNtRnJTbkpPZGtKdlUyUmlNVWxNWWpKaQ0KT0dw
c05YbE1kVnh1YzFWbk5VZDFhbU56ZUM5Tk16TXZUakZOVW05cVpsVTNObEo0
TjJ4eVlVUkdkWEJtDQpkSHByYWpreVJrcG9UVlo0Y0hKSU9URndiV2RzVFdO
VlhHNXRhVmszTkV0SVEzcEpNMWRyZEVoRU4ydHINCmRIRnFRVTlCVUVVM1pV
SlRORE4xUjFaYVJGb3JlWGM5UFZ4dUlpd2lhWFlpt2lKV00yRnNVbk5RTjJk
Sg0KU1hNMGExaE9SVGR2V2pKQlBUMWNiaUo5DQo=',
  max_historical_user_count: 10,
  active_users: 6
}
</code></pre>

</details>

You can view the exact JSON payload in the administration panel. To view the payload:

1. Navigate to **Admin Area > Settings > Metrics and profiling** and expand **Seat Link**.
1. Click **Preview payload**.

#### Disable Seat Link

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/212375) in [GitLab Starter](https://about.gitlab.com/pricing/) 12.10.

Seat Link is enabled by default.

To disable this feature, go to **Admin Area > Settings > Metrics and profiling**, uncheck the **Enable Seat Link** checkbox > **Save changes**.

To disable Seat Link in an Omnibus GitLab installation, and prevent it from
being configured in the future through the administration panel, set the following in
[`gitlab.rb`](https://docs.gitlab.com/omnibus/settings/configuration.html#configuration-options):

```ruby
gitlab_rails['seat_link_enabled'] = false
```

To disable Seat Link in a GitLab source installation, and prevent it from
being configured in the future through the administration panel,
set the following in `gitlab.yml`:

```yaml
production: &base
  # ...
  gitlab:
    # ...
    seat_link_enabled: false
```

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

When your subscription or trial expires, GitLab does not delete your data, but it
may become inaccessible, depending on the tier at expiry. Some features may not
behave as expected if you're not prepared for the expiry. For example,
[environment specific variables not being passed](https://gitlab.com/gitlab-org/gitlab/-/issues/24759).
If you renew or upgrade, your data is again accessible.

For self-managed customers, there is a 14-day grace period when your features
continue to work as-is, after which the entire instance becomes read
only.

However, if you remove the license, you immediately revert to Core
features, and the instance become read / write again.

## Customers Portal

GitLab provides the [Customers Portal](../index.md#customers-portal) where you can
manage your subscriptions and your account details.

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
