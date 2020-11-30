---
stage: fulfillment
group: fulfillment
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: index, reference
---

# GitLab.com subscription **(BRONZE ONLY)**

GitLab.com is GitLab Inc.'s software-as-a-service offering. You don't need to
install anything to use GitLab.com, you only need to
[sign up](https://gitlab.com/users/sign_up) and start using GitLab straight away.

This page reviews the details of your GitLab.com subscription.

## Choose a GitLab.com group or personal subscription

On GitLab.com you can apply a subscription to either a group or a personal namespace.

When applied to:

- A **group**, the group, all subgroups, and all projects under the selected
  group on GitLab.com contains the features of the associated tier. GitLab recommends
  choosing a group plan when managing an organization's projects and users.
- A **personal userspace**, all projects contain features with the
  subscription applied, but as it's not a group, group features aren't available.

You can read more about [common misconceptions](https://about.gitlab.com/handbook/marketing/strategic-marketing/enablement/dotcom-subscriptions/#common-misconceptions) regarding a GitLab.com subscription to help avoid issues.

## Choose a GitLab.com tier

Pricing is [tier-based](https://about.gitlab.com/pricing/), allowing you to choose
the features which fit your budget. For information on what features are available
at each tier, see the
[GitLab.com feature comparison](https://about.gitlab.com/pricing/gitlab-com/feature-comparison/).

## Choose the number of users

NOTE: **Note:**
Applied only to groups.

A GitLab.com subscription uses a concurrent (_seat_) model. You pay for a
subscription according to the maximum number of users enabled at once. You can
add and remove users during the subscription period, as long as the total users
at any given time doesn't exceed the subscription count.

Every occupied seat is counted in the subscription, with the following exception:

- Members with Guest permissions on a Gold subscription.

TIP: **Tip:**
To support the open source community and encourage the development of open
source projects, GitLab grants access to **Gold** features for all GitLab.com
**public** projects, regardless of the subscription.

## Obtain a GitLab.com subscription

To subscribe to GitLab.com:

- **For individuals**:
  1. Create a user account for yourself using our
     [sign up page](https://gitlab.com/users/sign_up).
  1. Visit the [billing page](https://gitlab.com/profile/billings)
     under your profile.
  1. Select the **Bronze**, **Silver**, or **Gold** GitLab.com plan through the
     [Customers Portal](https://customers.gitlab.com/).
  1. Link your GitLab.com account with your Customers Portal account.
     Once a plan has been selected, if your account is not
     already linked, GitLab prompts you to link your account with a
     **Sign in to GitLab.com** button.
  1. Select the namespace from the drop-down list to associate the subscription.
  1. Proceed to checkout.
- **For groups**:
  1. Create a user account for yourself using our
     [sign up page](https://gitlab.com/users/sign_up).
  1. Create a [group](../../user/group/index.md). GitLab groups help assemble related
     projects together allowing you to grant members access to several projects
     at once. A group is not required if you plan on having projects inside a personal
     namespace.
  1. Create additional users and
     [add them to the group](../../user/group/index.md#add-users-to-a-group).
  1. Select the **Bronze**, **Silver**, or **Gold** GitLab.com plan through the
     [Customers Portal](https://customers.gitlab.com/).
  1. Link your GitLab.com account with your Customers Portal account.
     Once a plan has been selected, if your account is not
     already linked, GitLab prompts you to link your account with a
     **Sign in to GitLab.com** button.
  1. Select the namespace from the drop-down list to associate the subscription.
  1. Proceed to checkout.

TIP: **Tip:**
You can also go to the [**My Account**](https://customers.gitlab.com/customers/edit)
page to add or change the GitLab.com account link.

## View your GitLab.com subscription

To see the status of your GitLab.com subscription, log in to GitLab.com and go
to the **Billing** section of the relevant namespace:

- **For individuals**: Visit the [billing page](https://gitlab.com/profile/billings)
  under your profile.
- **For groups**: From the group page (*not* from a project in the group), go to **Settings > Billing**.

  NOTE: **Note:**
  You must have Owner level [permissions](../../user/permissions.md) to view a group's billing page.

  The following table describes details of your subscription for groups:

  | Field                   | Description                                                                                                                             |
  |-------------------------|-----------------------------------------------------------------------------------------------------------------------------------------|
  | **Seats in subscription**   | If this is a paid plan, represents the number of seats you've paid to support in your group.                                            |
  | **Seats currently in use** | Number of seats in use.                                                                                                |
  | **Max seats used**          | Highest number of seats you've used. If this exceeds the seats in subscription, you may owe an additional fee for the additional users. |
  | **Seats owed**              | If your maximum seats used exceeds the seats in your subscription, you owe an additional fee for the users you've added.             |
  | **Subscription start date** | Date your subscription started. If this is for a Free plan, is the date you transitioned off your group's paid plan.                    |
  | **Subscription end date**   | Date your current subscription ends. Does not apply to Free plans.                                                                  |
  | **Billable users list**   | List of users that belong to your group subscription. Does not apply to Free plans.                                                       |

## Renew your GitLab.com subscription

To renew your subscription:

1. [Prepare for renewal by reviewing your account](#prepare-for-renewal-by-reviewing-your-account)
1. [Renew your GitLab.com subscription](#renew-or-change-a-gitlabcom-subscription)

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

- A GitLab subscription is based on the number of users. You could pay more than
  you should if you renew for too many users, while the renewal fails if you
  attempt to renew a subscription for too few users.
- Stale user accounts can be a security risk. A regular review helps reduce this risk.

#### Users over License

A GitLab subscription is valid for a specific number of users. For details, see
[Choose the number of users](#choose-the-number-of-users).

If the number of [billable users](#view-your-gitlabcom-subscription) exceeds the number included in the subscription, known
as the number of _users over license_, you must pay for the excess number of
users either before renewal, or at the time of renewal. This is also known the
_true up_ process.

### Renew or change a GitLab.com subscription

You can adjust the number of users before renewing your GitLab.com subscription.

- To renew for more users than are currently included in your GitLab.com plan, [add users to your subscription](#add-users-to-your-subscription).
- To renew for fewer users than are currently included in your GitLab.com plan,
either [disable](../../user/admin_area/activating_deactivating_users.md#deactivating-a-user) or [block](../../user/admin_area/blocking_unblocking_users.md#blocking-a-user) the user accounts you no longer need.

For details on upgrading your subscription tier, see
[Upgrade your GitLab.com subscription tier](#upgrade-your-gitlabcom-subscription-tier).

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

## Upgrade your GitLab.com subscription tier

To upgrade your [GitLab tier](https://about.gitlab.com/pricing/):

1. Log in to the [Customers Portal](https://customers.gitlab.com/customers/sign_in).
1. Select **Upgrade** on the relevant subscription card on the
   [Manage purchases](https://customers.gitlab.com/subscriptions) page.
1. Select the desired upgrade.
1. Confirm the active form of payment, or add a new form of payment.
1. Check the **I accept the Privacy Policy and Terms of Service** checkbox.
1. Select **Confirm purchase**.

When the purchase has been processed, you receive confirmation of your new subscription tier.

## See your billable users list

To see a list of your billable users on your GitLab group page go to **Settings > Billing**. This page provides information about your subscription and occupied seats for your group which is the list of billable users for your particular group.

## Subscription expiry

When your subscription or trial expires, GitLab does not delete your data, but
it may become inaccessible, depending on the tier at expiry. Some features may not
behave as expected if you're not prepared for the expiry. For example,
[environment specific variables not being passed](https://gitlab.com/gitlab-org/gitlab/-/issues/24759).

If you renew or upgrade, your data is accessible again.

## CI pipeline minutes

CI pipeline minutes are the execution time for your
[pipelines](../../ci/pipelines/index.md) on GitLab's shared runners. Each
[GitLab.com tier](https://about.gitlab.com/pricing/) includes a monthly quota
of CI pipeline minutes:

- Free: 400 minutes
- Bronze: 2,000 minutes
- Silver: 10,000 minutes
- Gold: 50,000 minutes

Quotas apply to:

- Groups, where the minutes are shared across all members of the group, its
  subgroups, and nested projects. To view the group's usage, navigate to the group,
  then **Settings > Usage Quotas**.
- Your personal account, where the minutes are available for your personal projects.
  To view and buy personal minutes, click your avatar, then
  **Settings > [Usage Quotas](https://gitlab.com/profile/usage_quotas#pipelines-quota-tab)**.

Only pipeline minutes for GitLab shared runners are restricted. If you have a
specific runner set up for your projects, there is no limit to your build time on GitLab.com.

The available quota is reset on the first of each calendar month at midnight UTC.

When the CI minutes are depleted, an email is sent automatically to notify the owner(s)
of the namespace. You can [purchase additional CI minutes](#purchase-additional-ci-minutes),
or upgrade your account to [Silver or Gold](https://about.gitlab.com/pricing/).
Your own runners can still be used even if you reach your limits.

### Purchase additional CI minutes

If you're using GitLab.com, you can purchase additional CI minutes so your
pipelines aren't blocked after you have used all your CI minutes from your
main quota. You can find pricing for additional CI/CD minutes in the
[GitLab Customers Portal](https://customers.gitlab.com/plans). Additional minutes:

- Are only used after the shared quota included in your subscription runs out.
- Roll over month to month.

To purchase additional minutes for your group on GitLab.com:

1. From your group, go to **Settings > Usage Quotas**.
1. Select **Buy additional minutes** and GitLab directs you to the Customers Portal.
1. Locate the subscription card that's linked to your group on GitLab.com, click **Buy more CI minutes**, and complete the details about the transaction.
1. Once we have processed your payment, the extra CI minutes are synced to your group namespace.
1. To confirm the available CI minutes, go to your group, then **Settings > Usage Quotas**.

   The **Additional minutes** displayed now includes the purchased additional CI minutes, plus any minutes rolled over from last month.

To purchase additional minutes for your personal namespace:

1. Click your avatar, then go to **Settings > Usage Quotas**.
1. Select **Buy additional minutes** and GitLab redirects you to the Customers Portal.
1. Locate the subscription card that's linked to your personal namespace on GitLab.com, click **Buy more CI minutes**, and complete the details about the transaction. Once we have processed your payment, the extra CI minutes are synced to your personal namespace.
1. To confirm the available CI minutes for your personal projects, click your avatar, then go to **Settings > Usage Quotas**.

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
