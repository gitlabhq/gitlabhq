---
stage: Fulfillment
group: Purchase
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: index, reference
---

# GitLab SaaS subscription **(PREMIUM SAAS)**

GitLab SaaS is the GitLab software-as-a-service offering, which is available at GitLab.com.
You don't need to install anything to use GitLab SaaS, you only need to
[sign up](https://gitlab.com/users/sign_up).

This page reviews the details of your GitLab SaaS subscription.

## Choose a GitLab SaaS tier

Pricing is [tier-based](https://about.gitlab.com/pricing/), so you can choose
the features that fit your budget. For information on the features available
for each tier, see the
[GitLab SaaS feature comparison](https://about.gitlab.com/pricing/gitlab-com/feature-comparison/).

## Choose the number of users

NOTE:
Applied only to groups.

A GitLab SaaS subscription uses a concurrent (_seat_) model. You pay for a
subscription according to the maximum number of users enabled at once. You can
add and remove users during the subscription period, as long as the total users
at any given time doesn't exceed the subscription count.

Every occupied seat is counted in the subscription, with the following exception:

- Members with Guest permissions on an Ultimate subscription.

NOTE:
To support the open source community and encourage the development of open
source projects, GitLab grants access to **Ultimate** features for all GitLab SaaS
**public** projects, regardless of the subscription. GitLab also provides qualifying
open source projects with 50,000 CI minutes and free access to the Ultimate tier for
groups through the [GitLab for Open Source program](https://about.gitlab.com/solutions/open-source/).

## Obtain a GitLab SaaS subscription

To subscribe to GitLab SaaS:

1. Create a user account for yourself using our
   [sign up page](https://gitlab.com/users/sign_up).
1. Create a [group](../../user/group/index.md). GitLab groups help assemble related
   projects together allowing you to grant members access to several projects
   at once. A group is not required if you plan on having projects inside a personal
   namespace.
1. Create additional users and
   [add them to the group](../../user/group/index.md#add-users-to-a-group).
1. Select the GitLab SaaS plan through the
   [Customers Portal](https://customers.gitlab.com/).
1. Link your GitLab SaaS account with your Customers Portal account.
   Once a plan has been selected, if your account is not
   already linked, GitLab prompts you to link your account with a
   **Sign in to GitLab.com** button.
1. Select the namespace from the drop-down list to associate the subscription.
1. Proceed to checkout.

NOTE:
You can also go to the [**My Account**](https://customers.gitlab.com/customers/edit)
page to add or change the GitLab SaaS account link.

## View your GitLab SaaS subscription

To see the status of your GitLab SaaS subscription, log in to GitLab SaaS and go
to the **Billing** section:

NOTE:
You must have Owner level [permissions](../../user/permissions.md) to view the billing page.

The following table describes details of your subscription:

| Field                       | Description |
|:----------------------------|:------------|
| **Seats in subscription**   | If this is a paid plan, represents the number of seats you've bought for this group. |
| **Seats currently in use**  | Number of seats in use. Select **See usage** to see a list of the users using these seats. For more details, see [Seat usage](#seat-usage). |
| **Max seats used**          | Highest number of seats you've used. |
| **Seats owed**              | _Seats owed_ = _Max seats used_ - _Seats in subscription_. |
| **Subscription start date** | Date your subscription started. If this is for a Free plan, it's the date you transitioned off your group's paid plan. |
| **Subscription end date**   | Date your current subscription ends. Does not apply to Free plans. |

## Seat usage

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/216899) in GitLab 13.5.
> - [Updated](https://gitlab.com/gitlab-org/gitlab/-/issues/292086) in GitLab 13.8 to include public
    email address.

To view a list of seats being used, go to **Settings > Billing**.
Under **Seats currently in use**, select **See usage**.

The **Seat usage** page lists all users occupying seats. Details for each user include:

- Full name
- Username
- Public email address (if they have provided one in their [user settings](../../user/profile/index.md#access-your-user-settings))

The Seat usage listing is updated live, but the usage statistics on the billing page are updated
only once per day. For this reason there can be a minor difference between the seat usage listing
and the billing page.

### Search seat usage

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/262875) in GitLab 13.8.

To search users in the **Seat usage** page, enter a string in the search field. A minimum of 3
characters are required.

The search returns those users whose first name, last name, or username contain the search string.

For example:

| First name | Search string | Match ? |
|:-----------|:--------------|:--------|
| Amir       | `ami`         | Yes     |
| Amir       | `amr`         | No      |

## Subscription expiry

When your subscription expires, you can continue to use paid features of GitLab for 14 days.
On the 15th day, paid features are no longer available. You can
continue to use free features.

To resume paid feature functionality, purchase a new subscription.

## Renew your GitLab SaaS subscription

To renew your subscription:

1. [Prepare for renewal by reviewing your account.](#prepare-for-renewal-by-reviewing-your-account)
1. [Renew your GitLab SaaS subscription.](#renew-or-change-a-gitlab-saas-subscription)

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

- A GitLab subscription is based on the number of users. You could pay more than
  you should if you renew for too many users, while the renewal fails if you
  attempt to renew a subscription for too few users.
- Stale user accounts can be a security risk. A regular review helps reduce this risk.

#### Seats owed

A GitLab subscription is valid for a specific number of users. For details, see
[Choose the number of users](#choose-the-number-of-users).

If the number of [billable users](#view-your-gitlab-saas-subscription) exceeds the number included in the subscription, known
as the number of _seats owed_, you must pay for the excess number of users before renewal.

##### Seats owed example

You purchase a subscription for 10 users.

| Event                                              | Billable members | Maximum users |
|:---------------------------------------------------|:-----------------|:--------------|
| Ten users occupy all 10 seats.                     | 10               | 10            |
| Two new users join.                                | 12               | 12            |
| Three users leave and their accounts are removed.  | 9                | 12            |

Seats owed = 12 - 10 (Maximum users - users in subscription)

### Renew or change a GitLab SaaS subscription

Starting 30 days before a subscription expires, GitLab notifies group owners
of the date of expiry with a banner in the GitLab user interface.

We recommend following these steps during renewal:

1. Prune any [inactive or unwanted users](#remove-billable-user).
1. Determine if you have a need for user growth in the upcoming subscription.
1. Log in to the [Customers Portal](https://customers.gitlab.com/customers/sign_in) and beneath your existing subscription, select the **Renew** button.
1. Review your renewal details and complete the payment process.
1. Select **Confirm purchase**.

Your updated subscription is applied to your namespace on the renewal period start date.

An invoice is generated for the renewal and available for viewing or download on the [View invoices](https://customers.gitlab.com/receipts) page. If you have difficulty during the renewal process, contact our [support team](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=360000071293) for assistance.

For details on upgrading your subscription tier, see
[Upgrade your GitLab SaaS subscription tier](#upgrade-your-gitlab-saas-subscription-tier).

#### Automatic renewal

To view or change automatic subscription renewal (at the same tier as the
previous period), log in to the [Customers Portal](https://customers.gitlab.com/customers/sign_in), and:

- If you see a **Resume subscription** button, your subscription was canceled
  previously. Click it to resume automatic renewal.
- If you see **Cancel subscription**, your subscription is set to automatically
  renew at the end of the subscription period. Click it to cancel automatic renewal.

With automatic renewal enabled, the subscription automatically renews on the
expiration date without a gap in available service. An invoice is
generated for the renewal and available for viewing or download in the
[View invoices](https://customers.gitlab.com/receipts) page. If you have difficulty
during the renewal process, contact our
[support team](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=360000071293) for assistance.

## Add users to your subscription

You can add users to your subscription at any time during the subscription period. The cost of
additional users added during the subscription period is prorated from the date of purchase through
the end of the subscription period.

To add users to a subscription:

1. Log in to the [Customers Portal](https://customers.gitlab.com/).
1. Navigate to the **Manage Purchases** page.
1. Select **Add more seats** on the relevant subscription card.
1. Enter the number of additional users.
1. Select **Proceed to checkout**.
1. Review the **Subscription Upgrade Detail**. The system lists the total price for all users on the
   system and a credit for what you've already paid. You are only be charged for the net change.
1. Select **Confirm Upgrade**.

The following is emailed to you:

- A payment receipt. You can also access this information in the Customers Portal under
  [**View invoices**](https://customers.gitlab.com/receipts).

## Upgrade your GitLab SaaS subscription tier

To upgrade your [GitLab tier](https://about.gitlab.com/pricing/):

1. Log in to the [Customers Portal](https://customers.gitlab.com/customers/sign_in).
1. Select **Upgrade** on the relevant subscription card on the
   [Manage purchases](https://customers.gitlab.com/subscriptions) page.
1. Select the desired upgrade.
1. Confirm the active form of payment, or add a new form of payment.
1. Check the **I accept the Privacy Policy and Terms of Service** checkbox.
1. Select **Confirm purchase**.

When the purchase has been processed, you receive confirmation of your new subscription tier.

## See your subscription and billable users in GitLab.com

To view information about your subscription and occupied seats:

1. Go to your group's **Settings > Billing** page.
1. In the **Seats currently in use** area, select **See usage**.

### Remove billable user

To remove a billable user:

1. Go to your group's **Settings > Billing** page.
1. In the **Seats currently in use** area, select **See usage**.
1. In the row for the user you want to remove, on the right side, select the ellipsis and **Remove user**.
1. Re-type the username and select **Remove user**.

If you add a member to a group by using the [share a group with another group](../../user/group/index.md#share-a-group-with-another-group) feature, you can't remove the member by using this method. Instead, you can either:

- Remove the member from the shared group. You must be a group owner to do this.
- From the group's membership page, remove access from the entire shared group.

## CI pipeline minutes

CI pipeline minutes are the execution time for your [pipelines](../../ci/pipelines/index.md)
on GitLab shared runners. Each [GitLab SaaS tier](https://about.gitlab.com/pricing/)
includes a monthly quota of CI pipeline minutes for private and public projects:

| Plan     | Private projects | Public projects |
|----------|------------------|-----------------|
| Free     | 400              | 50,000          |
| Premium  | 10,000           | 1,250,000       |
| Ultimate | 50,000           | 6,250,000       |

Quotas apply to:

- Groups, where the minutes are shared across all members of the group, its
  subgroups, and nested projects. To view the group's usage, navigate to the group,
  then **Settings > Usage Quotas**.
- Your personal account, where the minutes are available for your personal projects.
  To view and buy personal minutes:

  1. In the top-right corner, select your avatar.
  1. Select **Edit profile**.
  1. In the left sidebar, select **[Usage Quotas](https://gitlab.com/-/profile/usage_quotas#pipelines-quota-tab)**.

Only pipeline minutes for GitLab shared runners are restricted. If you have a
specific runner set up for your projects, there is no limit to your build time on GitLab SaaS.

The available quota is reset on the first of each calendar month at midnight UTC.

When the CI minutes are depleted, an email is sent automatically to notify the owner(s)
of the namespace. You can [purchase additional CI minutes](#purchase-additional-ci-minutes),
or upgrade your account to a higher [plan](https://about.gitlab.com/pricing/).
Your own runners can still be used even if you reach your limits.

### Purchase additional CI minutes

If you're using GitLab SaaS, you can purchase additional CI minutes so your
pipelines aren't blocked after you have used all your CI minutes from your
main quota. You can find pricing for additional CI/CD minutes in the
[GitLab Customers Portal](https://customers.gitlab.com/plans). Additional minutes:

- Are only used after the shared quota included in your subscription runs out.
- Roll over month to month.

To purchase additional minutes for your group on GitLab SaaS:

1. From your group, go to **Settings > Usage Quotas**.
1. Select **Buy additional minutes** and GitLab directs you to the Customers Portal.
1. Locate the subscription card that's linked to your group on GitLab SaaS, click **Buy more CI minutes**, and complete the details about the transaction.
1. Once we have processed your payment, the extra CI minutes are synced to your group namespace.
1. To confirm the available CI minutes, go to your group, then **Settings > Usage Quotas**.

   The **Additional minutes** displayed now includes the purchased additional CI minutes, plus any minutes rolled over from last month.

To purchase additional minutes for your personal namespace:

1. In the top-right corner, select your avatar.
1. Select **Edit profile**.
1. In the left sidebar, select **Usage Quotas**.
1. Select **Buy additional minutes** and GitLab redirects you to the Customers Portal.
1. Locate the subscription card that's linked to your personal namespace on GitLab SaaS, click **Buy more CI minutes**, and complete the details about the transaction. Once we have processed your payment, the extra CI minutes are synced to your personal namespace.
1. To confirm the available CI minutes for your personal projects, go to the **Usage Quotas** settings again.

   The **Additional minutes** displayed now includes the purchased additional CI minutes, plus any minutes rolled over from last month.

Be aware that:

- If you have purchased extra CI minutes before the purchase of a paid plan,
  we calculate a pro-rated charge for your paid plan. That means you may
  be charged for less than one year because your subscription was previously
  created with the extra CI minutes.
- After the extra CI minutes have been assigned to a Group, they can't be transferred
  to a different Group.
- If you have used more minutes than your default quota, these minutes will
  be deducted from your Additional Minutes quota immediately after your purchase of additional
  minutes.

## Storage subscription

Projects have a free storage quota of 10 GB. To exceed this quota you must first [purchase one or
more storage subscription units](#purchase-more-storage). Each unit provides 10 GB of additional
storage per namespace. A storage subscription is renewed annually. For more details, see
[Usage Quotas](../../user/usage_quotas.md).

When the amount of purchased storage reaches zero, all projects over the free storage quota are
locked. Projects can only be unlocked by purchasing more storage subscription units.

### Purchase more storage

To purchase more storage for either a personal or group namespace:

1. Sign in to GitLab SaaS.
1. From either your personal homepage or the group's page, go to **Settings > Usage Quotas**.
1. For each locked project, total by how much its **Usage** exceeds the free quota and purchased
   storage. You must purchase the storage increment that exceeds this total.
1. Click **Purchase more storage** and you are taken to the Customers Portal.
1. Click **Add new subscription**.
1. Scroll to **Purchase add-on subscriptions** and select **Buy storage subscription**.
1. In the **Subscription details** section select the name of the user or group from the dropdown.
1. Enter the desired quantity of storage packs.
1. In the **Billing information** section select the payment method from the dropdown.
1. Select the **Privacy Policy** and **Terms of Service** checkbox.
1. Select **Buy subscription**.
1. Sign out of the Customers Portal.
1. Switch back to the GitLab SaaS tab and refresh the page.

The **Purchased storage available** total is incremented by the amount purchased. All locked
projects are unlocked and their excess usage is deducted from the additional storage.

## Customers Portal

The GitLab [Customers Portal](../index.md#customers-portal) enables you to manage your subscriptions
and account details.

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
