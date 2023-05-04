---
stage: Fulfillment
group: Purchase
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
type: index, reference
---

# GitLab SaaS subscription **(PREMIUM SAAS)**

GitLab SaaS is the GitLab software-as-a-service offering, which is available at GitLab.com.
You don't need to install anything to use GitLab SaaS, you only need to
[sign up](https://gitlab.com/users/sign_up). When you sign up, you choose:

- [A subscription](https://about.gitlab.com/pricing/).
- [The number of seats you want](#how-seat-usage-is-determined).

The subscription determines which features are available for your private projects. Organizations with public open source projects can actively apply to our [GitLab for Open Source Program](https://about.gitlab.com/solutions/open-source/join/).

Qualifying open source projects also get 50,000 CI/CD minutes and free access to the **Ultimate** tier
through the [GitLab for Open Source program](https://about.gitlab.com/solutions/open-source/).

## Obtain a GitLab SaaS subscription

A GitLab SaaS subscription applies to a top-level group.
Members of every subgroup and project in the group:

- Can use the features of the subscription.
- Consume seats in the subscription.

To subscribe to GitLab SaaS:

1. View the [GitLab SaaS feature comparison](https://about.gitlab.com/pricing/feature-comparison/)
   and decide which tier you want.
1. Create a user account for yourself by using the
   [sign up page](https://gitlab.com/users/sign_up).
1. Create a [group](../../user/group/manage.md#create-a-group). Your subscription tier applies to the top-level group, its subgroups, and projects.
1. Create additional users and
   [add them to the group](../../user/group/manage.md#add-users-to-a-group). The users in this group, its subgroups, and projects can use
   the features of your subscription tier, and they consume a seat in your subscription.
1. On the left sidebar, select **Settings > Billing** and choose a tier.
1. Fill out the form to complete your purchase.

## View your GitLab SaaS subscription

Prerequisite:

- You must have the Owner role for the group.

To see the status of your GitLab SaaS subscription:

1. On the top bar, select **Main menu > Groups** and find your group.
1. On the left sidebar, select **Settings > Billing**.

The following information is displayed:

| Field                       | Description |
|:----------------------------|:------------|
| **Seats in subscription**   | If this is a paid plan, represents the number of seats you've bought for this group. |
| **Seats currently in use**  | Number of seats in use. Select **See usage** to see a list of the users using these seats. |
| **Max seats used**          | Highest number of seats you've used. |
| **Seats owed**              | **Max seats used** minus **Seats in subscription**. |
| **Subscription start date** | Date your subscription started. If this is for a Free plan, it's the date you transitioned off your group's paid plan. |
| **Subscription end date**   | Date your current subscription ends. Does not apply to Free plans. |

## How seat usage is determined

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/216899) in GitLab 13.5.
> - [Updated](https://gitlab.com/gitlab-org/gitlab/-/issues/292086) in GitLab 13.8 to include public
    email address.

A GitLab SaaS subscription uses a concurrent (_seat_) model. You pay for a
subscription according to the maximum number of users assigned to the top-level group or its children during the billing period. You can
add and remove users during the subscription period without incurring additional charges, as long as the total users
at any given time doesn't exceed the subscription count. If the total users exceeds your subscription count, you will incur an overage
which must be paid at your next [reconciliation](../quarterly_reconciliation.md).

A top-level group can be [changed](../../user/group/manage.md#change-a-groups-path) like any other group.

Every user is included in seat usage, with the following exceptions:

- Users who are pending approval.
- Members with the [Guest role on an Ultimate subscription](#free-guest-users).
- GitLab-created service accounts:
  - [Ghost User](../../user/profile/account/delete_account.md#associated-records).
  - Bots such as:
    - [Support Bot](../../user/project/service_desk.md#support-bot-user).
    - [Bot users for projects](../../user/project/settings/project_access_tokens.md#bot-users-for-projects).
    - [Bot users for groups](../../user/group/settings/group_access_tokens.md#bot-users-for-groups).

Seat usage is reviewed [quarterly or annually](../quarterly_reconciliation.md).

If a user navigates to a different top-level group (one they have created themselves, for example)
and that group does not have a paid subscription, they would not see any of the paid features.

It is also possible for users to belong to two different top-level groups with different subscriptions.
In this case, they would see only the features available to that subscription.

### View seat usage

To view a list of seats being used:

1. On the top bar, select **Main menu > Groups** and find your group.
1. On the left sidebar, select **Settings > Usage Quotas**.
1. On the **Seats** tab, view usage information.

The data in seat usage listing, **Seats in use**, and **Seats in subscription** are updated live.
The counts for **Max seats used** and **Seats owed** are updated once per day.

To view your subscription information and a summary of seat counts:

1. On the top bar, select **Main menu > Groups** and find your group.
1. On the left sidebar, select **Settings > Billing**.

The usage statistics are updated once per day, which may cause
a difference between the information in the **Usage Quotas** page and the **Billing page**.

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

### Export seat usage

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/262877) in GitLab 14.2.

To export seat usage data as a CSV file:

1. On the top bar, select **Main menu > Groups** and find your group.
1. On the left sidebar, select **Settings > Billing**.
1. Under **Seats currently in use**, select **See usage**.
1. Select **Export list**.

The generated list contains all seats being used,
and is not affected by the current search.

## Seats owed

A GitLab subscription is valid for a specific number of users.

If the number of billable users exceeds the number included in the subscription, known
as the number of **seats owed**, you must pay for the excess number of users.

For example, if you purchase a subscription for 10 users:

| Event                                              | Billable members | Maximum users |
|:---------------------------------------------------|:-----------------|:--------------|
| Ten users occupy all 10 seats.                     | 10               | 10            |
| Two new users join.                                | 12               | 12            |
| Three users leave and their accounts are removed.  | 9                | 12            |

Seats owed = 12 - 10 (Maximum users - users in subscription)

### Free Guest users **(ULTIMATE)**

In the **Ultimate** tier, users who are assigned the Guest role do not consume a seat.
The user must not be assigned any other role, anywhere in the instance or in the namespace for GitLab SaaS.

- If your project is private or internal, a user with the Guest role has
  [a set of permissions](../../user/permissions.md#project-members-permissions).
- If your project is public, all users, including those with the Guest role
  can access your project.

### Add seats to your subscription

Your subscription cost is based on the maximum number of seats you use during the billing period.
Even if you reach the number of seats in your subscription, you can continue to add users.
GitLab [bills you for the overage](../quarterly_reconciliation.md).

To add seats to a subscription:

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

### Remove users from your subscription

To remove a billable user from your subscription:

1. On the top bar, select **Main menu > Groups** and find your group.
1. On the left sidebar, select **Settings > Billing**.
1. In the **Seats currently in use** section, select **See usage**.
1. In the row for the user you want to remove, on the right side, select the ellipsis and **Remove user**.
1. Re-type the username and select **Remove user**.

If you add a member to a group by using the [share a group with another group](../../user/group/manage.md#share-a-group-with-another-group) feature, you can't remove the member by using this method. Instead, you can either:

- Remove the member from the shared group. You must be a group owner to do this.
- From the group's membership page, remove access from the entire shared group.

## Seat usage alerts

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/348481) in GitLab 15.2 [with a flag](../../administration/feature_flags.md) named `seat_flag_alerts`.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/362041) in GitLab 15.4. Feature flag `seat_flag_alerts` removed.

If you have the Owner role of the top-level group, an alert notifies you
of your total seat usage.

The alert displays on group, subgroup, and project
pages, and only for top-level groups linked to subscriptions enrolled
in [quarterly subscription reconciliations](../quarterly_reconciliation.md).
After you dismiss the alert, it doesn't display until another seat is used.

The alert displays based on the following seat usage. You cannot configure the
amounts at which the alert displays.

| Seats in subscription | Seat usage                                                             |
|-----------------------|------------------------------------------------------------------------|
| 0-15                  | One seat remaining in the subscription.                                |
| 16-25                 | Two seats remaining in the subscription.                               |
| 26-99                 | 10% of seats have been used.                                           |
| 100-999               | 8% of seats have been used.                                            |
| 1000+                 | 5% of seats have been used                                             |

## Change the linked namespace

To change the namespace linked to a subscription:

1. Log in to the [Customers Portal](https://customers.gitlab.com/customers/sign_in) with a
   [linked](../customers_portal.md#link-a-gitlabcom-account) GitLab.com account.
1. Go to the **Manage Purchases** page.
1. Select **Change linked namespace**.
1. Select the desired group from the **New Namespace** dropdown list. For a group to appear here, you must have the Owner role for that group.
1. If the [total number of users](#view-seat-usage) in your group exceeds the number of seats in your subscription,
   you are prompted to pay for the additional users. Subscription charges are calculated based on
   the total number of users in a group, including its subgroups and nested projects.

   If you purchased your subscription through an authorized reseller, you are unable to pay for additional users.
   You can either:

   - Remove additional users, so that no overage is detected.
   - Contact the partner to purchase additional seats now or at the end of your subscription term.

1. Select **Confirm changes**.

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For a demo, see [Linking GitLab Subscription to the Namespace](https://youtu.be/qAq8pyFP-a0).

Only one namespace can be linked to a subscription.

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

Before you renew your subscription:

1. Log in to the [Customers Portal](https://customers.gitlab.com/customers/sign_in).
1. On the **Account details** page, verify or update the invoice contact details.
1. On the **Payment Methods** page, verify or update the credit card on file.
1. In GitLab, review your list of user accounts and [remove inactive or unwanted users](#remove-users-from-your-subscription).

### Renew or change a GitLab SaaS subscription

Starting 30 days before a subscription expires, GitLab notifies group owners
of the date of expiry with a banner in the GitLab user interface.

To renew your subscription:

1. Log in to the [Customers Portal](https://customers.gitlab.com/customers/sign_in) and beneath your existing subscription, select **Renew**.
The **Renew** button remains disabled (grayed-out) until 15 days before a subscription expires.
You can hover your mouse on the **Renew** button to see the date when it becomes active.
1. Review your renewal details and complete the payment process.
1. Select **Confirm purchase**.

Your updated subscription is applied to your namespace on the renewal period start date. It may take up to one day for the renewal to be processed.

An invoice is generated for the renewal and available for viewing or download on the [View invoices](https://customers.gitlab.com/receipts) page.
If you have difficulty during the renewal process, contact the [Support team](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=360000071293) for assistance.

For details on upgrading your subscription tier, see
[Upgrade your GitLab SaaS subscription tier](#upgrade-your-gitlab-saas-subscription-tier).

### Automatic subscription renewal

When a subscription is set to auto-renew, it renews automatically on the
expiration date without a gap in available service. Subscriptions purchased through Customers Portal or GitLab.com are set to auto-renew by default. The number of seats is adjusted to fit the [number of billable users in your group](#view-seat-usage) at the time of renewal. You can view and download your renewal invoice on the Customers Portal [View invoices](https://customers.gitlab.com/receipts) page. If your account has a [saved credit card](../customers_portal.md#change-your-payment-method), the card is charged for the invoice amount. If we are unable to process a payment or the auto-renewal fails for any other reason, you have 14 days to renew your subscription, after which your access is downgraded.

#### Email notifications

15 days before a subscription automatically renews, an email is sent with information about the renewal.

- If your credit card is expired, the email tells you how to update it.
- If you have any outstanding overages, the email tells you to contact our Sales team.
- If there are no issues, the email specifies the names and quantity of the products being renewed. The email also includes the total amount you owe. If your usage increases or decreases before renewal, this amount can change.

#### Enable or disable automatic subscription renewal

To view or change automatic subscription renewal (at the same tier as the
previous period), sign in to the [Customers Portal](https://customers.gitlab.com/customers/sign_in), and:

- If a **Resume subscription** button is displayed, your subscription was canceled
  previously. Select it to resume automatic renewal.
- If a **Cancel subscription** button is displayed, your subscription is set to automatically
  renew at the end of the subscription period. Select it to cancel automatic renewal.

If you have difficulty during the renewal process, contact the
[Support team](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=360000071293) for assistance.

## Add or change the contacts for your subscription

Contacts can renew a subscription, cancel a subscription, or transfer the subscription to a different namespace.

To change the contacts:

1. Ensure an account exists in the
   [Customers Portal](https://customers.gitlab.com/customers/sign_in) for the user you want to add.
1. Verify you have access to at least one of
   [these requirements](https://about.gitlab.com/handbook/support/license-and-renewals/workflows/customersdot/associating_purchases.html).
1. [Create a ticket with the Support team](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=360000071293). Include any relevant material in your request.

## CI/CD minutes

CI/CD minutes are the execution time for your [pipelines](../../ci/pipelines/index.md)
on GitLab shared runners.

Refer to [CI/CD minutes](../../ci/pipelines/cicd_minutes.md)
for more information.

### Purchase additional CI/CD minutes

You can [purchase additional minutes](../../ci/pipelines/cicd_minutes.md#purchase-additional-cicd-minutes)
for your personal or group namespace. CI/CD minutes are a **one-time purchase**, so they do not renew.

## Add-on subscription for additional Storage and Transfer

NOTE:
Free namespaces are subject to a 5 GB storage and 10 GB transfer [soft limit](https://about.gitlab.com/pricing/). Once all storage is available to view in the usage quota workflow, GitLab will automatically enforce the namespace storage limit and the project limit is removed. This change is announced separately. The storage and transfer add-on can be purchased to increase the limits.

Projects have a free storage quota of 10 GB. To exceed this quota you must first
[purchase one or more storage subscription units](#purchase-more-storage-and-transfer). Each unit provides 10 GB of additional
storage per namespace. A storage subscription is renewed annually. For more details, see
[Usage Quotas](../../user/usage_quotas.md).

When the amount of purchased storage reaches zero, all projects over the free storage quota are
locked. Projects can only be unlocked by purchasing more storage subscription units.

### Purchase more storage and transfer

Prerequisite:

- You must have the Owner role.

You can purchase a storage subscription for your personal or group namespace.

NOTE:
Storage subscriptions **[renew automatically](#automatic-subscription-renewal) each year**.
You can [cancel the subscription](#enable-or-disable-automatic-subscription-renewal) to disable the automatic renewal.

#### For your personal namespace

1. Sign in to GitLab SaaS.
1. From either your personal homepage or the group's page, go to **Settings > Usage Quotas**.
1. For each locked project, total by how much its **Usage** exceeds the free quota and purchased
   storage. You must purchase the storage increment that exceeds this total.
1. Select **Purchase more storage** and you are taken to the Customers Portal.
1. Select **Add new subscription**.
1. Scroll to **Purchase add-on subscriptions** and select **Buy storage subscription**.
1. In the **Subscription details** section select the name of the user or group from the dropdown list.
1. Enter the desired quantity of storage packs.
1. In the **Billing information** section select the payment method from the dropdown list.
1. Select the **Privacy Policy** and **Terms of Service** checkbox.
1. Select **Buy subscription**.
1. Sign out of the Customers Portal.
1. Switch back to the GitLab SaaS tab and refresh the page.

The **Purchased storage available** total is incremented by the amount purchased. All locked
projects are unlocked and their excess usage is deducted from the additional storage.

#### For your group namespace

> [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/5789) in GitLab 14.6.

If you're using GitLab SaaS, you can purchase additional storage so your
pipelines aren't blocked after you have used all your storage from your
main quota. You can find pricing for additional storage on the
[GitLab Pricing page](https://about.gitlab.com/pricing/).

To purchase additional storage for your group on GitLab SaaS:

1. On the top bar, select **Main menu > Groups** and find your group.
1. On the left sidebar, select **Settings > Usage Quotas**.
1. Select **Storage** tab.
1. Select **Purchase more storage**.
1. Complete the details.

After your payment is processed, the extra storage is available for your group
namespace.

To confirm the available storage, go to your group, and then select
**Settings > Usage Quotas** and select the **Storage** tab.

The **Purchased storage available** total is incremented by the amount purchased. All locked
projects are unlocked and their excess usage is deducted from the additional storage.

## Contact Support

Learn more about:

- The tiers of [GitLab Support](https://about.gitlab.com/support/).
- [Submit a request via the Support Portal](https://support.gitlab.com/hc/en-us/requests/new).

We also encourage you to search our project trackers for known issues and
existing feature requests in the [GitLab](https://gitlab.com/gitlab-org/gitlab/-/issues/) project.

These issues are the best avenue for getting updates on specific product plans
and for communicating directly with the relevant GitLab team members.

## Troubleshooting

### Credit card declined

If your credit card is declined when purchasing a GitLab subscription, possible reasons include:

- The credit card details provided are incorrect. The most common cause for this is an incomplete or fake address.
- The credit card account has insufficient funds.
- You are using a virtual credit card and it has insufficient funds, or has expired.
- The transaction exceeds the credit limit.
- The transaction exceeds the credit card's maximum transaction amount.

Check with your financial institution to confirm if any of these reasons apply. If they don't
apply, contact [GitLab Support](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=360000071293).

### Unable to link subscription to namespace

If you cannot link a subscription to your namespace, ensure that you have the Owner role
for that namespace.
