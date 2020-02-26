---
type: index, reference
---

# GitLab subscription

Access to GitLab features is provided on a subscription basis. A subscription entitles users to the features of a specific GitLab tier. Each tier provides a set of features. A subscription is valid for 12 months.

## Choosing a GitLab subscription

When choosing a subscription, consider the following factors:

- [GitLab tier](#choosing-a-gitlab-tier)
- [GitLab.com or self-managed](#choosing-between-gitlabcom-or-self-managed)
- [Group or personal subscription (GitLab.com only)](#choosing-a-gitlabcom-group-or-personal-subscription)
- [Number of users](#choosing-the-number-of-users)

### Choosing a GitLab tier

Pricing is [tier-based](https://about.gitlab.com/pricing/), allowing you to choose the features which fit your budget. See the [feature comparison](https://about.gitlab.com/pricing/gitlab-com/feature-comparison/) for information on what features are available at each tier.

### Choosing between GitLab.com or self-managed

There are some differences in how a subscription applies, depending if you use GitLab.com or a self-managed instance.

- [GitLab.com](#gitlabcom): GitLab's software-as-a-service offering. You don't need to install anything to use GitLab.com, you only need to [sign up](https://gitlab.com/users/sign_in) and start using GitLab straight away.
- [GitLab self-managed](#self-managed): Install, administer, and maintain your own GitLab instance.

On a self-managed instance, a GitLab subscription provides the same set of features for all users. On GitLab.com you can apply a subscription to either a group or a personal namespace.

### Choosing a GitLab.com group or personal subscription

On GitLab.com you can apply a subscription to either a group or a personal namespace.

When applied to:

- A **group**, the group, all subgroups, and all projects under the selected
  group on GitLab.com will have the features of the associated tier. GitLab recommends
  choosing a group plan when managing an organization's projects and users.
- A **personal userspace** instead, all projects will have features with the
  subscription applied, but as it's not a group, group features won't be available.

### Choosing the number of users

There are some differences between who is counted in a subscription, depending if you use GitLab.com or a self-managed instance.

#### GitLab.com

A GitLab.com subscription uses a concurrent (_seat_) model. You pay for a subscription according to the maximum number of users enabled at once. You can add and remove users during the subscription period, as long as the total users at any given time is within your subscription count.

Every occupied seat, whether by person, job, or bot is counted in the subscription, with the following exception:

- Members with Guest permissions on a Gold subscription.

TIP: **Tip:**
To support the open source community and encourage the development of open
source projects, GitLab grants access to **Gold** features for all GitLab.com
**public** projects, regardless of the subscription.

#### Self-managed

A self-managed subscription uses a hybrid model. You pay for a subscription according to the maximum number of users enabled during the subscription period. At the end of the subscription period, the maximum number of simultaneous users in the self-managed installation is checked. If the number of users is higher than your subscription, you are billed for the extra users. The maximum number of simultaneous users is also used to calculate the cost of subscription renewal.

Every occupied seat, whether by person, job, or bot is counted in the subscription, with the following exceptions:

- Blocked users who are blocked prior to the renewal of a subscription won't be counted as active users for the renewal subscription. They may count as active users in the subscription period in which they were originally added.
- Members with Guest permissions on an Ultimate subscription.
- Special internal GitLab accounts: `Ghost User` and `Support Bot`.

NOTE: **Note:**
If you have LDAP integration enabled, anyone in the configured domain can sign up for a GitLab account. This can result in an unexpected bill at time of renewal. Consider [disabling new signups](../user/admin_area/settings/sign_up_restrictions.md) and managing new users manually instead.

## Obtain a GitLab subscription

### Subscribe to GitLab.com

To subscribe to GitLab.com:

1. Create a user account for yourself using our
   [sign up page](https://gitlab.com/users/sign_in#register-pane).
1. Create a [group](../user/group/index.md). GitLab groups help assemble related
   projects together allowing you to grant members access to several projects
   at once. A group is not required if you plan on having projects inside a personal
   namespace.
1. Create additional users and
   [add them to the group](../user/group/index.md#add-users-to-a-group).
1. Select the **Bronze**, **Silver**, or **Gold** GitLab.com plan through the
   [Customers Portal](https://customers.gitlab.com/).
1. Link your GitLab.com account with your Customers Portal account.
   Once signed into the Customers Portal, if your account is not
   already linked, you will be prompted to link your account with a
   **Link my GitLab Account** button.
1. Associate the group with the subscription.

TIP: **Tip:**
You can also go to the [**My Account**](https://customers.gitlab.com/customers/edit)
page to add or change the GitLab.com account link.

### Subscribe through GitLab self-managed

To subscribe to GitLab through a self-managed installation:

1. Go to the [Customers Portal](https://customers.gitlab.com/) and purchase a **Starter**, **Premium**, or **Ultimate** self-managed plan.
1. After purchase, a license file is sent to the email address associated to the Customers Portal account,
   which must be [uploaded to your GitLab instance](../user/admin_area/license.md#uploading-your-license).

TIP: **Tip:**
If you're purchasing a subscription for an existing **Core** self-managed
instance, ensure you're purchasing enough seats to
[cover your users](../user/admin_area/index.md#administering-users).

## Manage your GitLab account

With the [Customers Portal](https://customers.gitlab.com/) you can:

- [Change billing information](#change-billing-information)
- [Change the linked account](#change-the-linked-account)
- [Change the associated namespace](#change-the-associated-namespace)

### Change billing information

To change billing information:

1. Log in to [Customers Portal](https://customers.gitlab.com/customers/sign_in).
1. Go to the **My Account** page.
1. Make the required changes to the **Account Details** information.
1. Click **Update Account**.

NOTE: **Note:**
Future purchases will use the information in this section.
The email listed in this section is used for the Customers Portal
login and for license-related email communication.

### Change the linked account

To change the GitLab.com account associated with a Customers Portal
account:

1. Log in to the
   [Customers Portal](https://customers.gitlab.com/customers/sign_in).
1. Go to [GitLab.com](https://gitlab.com) in a separate browser tab. Ensure you
   are not logged in.
1. On the Customers Portal page, click
   [**My Account**](https://customers.gitlab.com/customers/edit) in the top menu.
1. Under **Your GitLab.com account**, click **Change linked account** button.
1. Log in to the [GitLab.com](https://gitlab.com) account you want to link to Customers Portal.

### Change the associated namespace

With a linked GitLab.com account:

1. Log in to the [Customers Portal](https://customers.gitlab.com/customers/sign_in).
1. Navigate to the **Manage Purchases** page.
1. Click **Change linked group**.
1. Select the desired group from the **This subscription is for** dropdown.
1. Click **Proceed to checkout**.

Subscription charges are calculated based on the total number of users in a group, including its subgroups and nested projects. If the total number of users exceeds the number of seats in your subscription, you will be charged for the additional users.

## View your subscription

To see the status of your GitLab.com subscription, log into GitLab.com and go to the **Billing** section of the relevant namespace:

- For individuals:
  1. Go to **User Avatar > Settings**.
  1. Click **Billing**.
- For groups:
  1. From the group page (*not* from a project within the group), go to **Settings > Billing**.

The following table describes details of your subscription for groups:

| Field | Description |
| ------ | ------ |
| Seats in subscription | If this is a paid plan, represents the number of seats you've paid to support in your group. |
| Seats currently in use | Number of active seats currently in use. |
| Max seats used | Highest number of seats you've used. If this exceeds the seats in subscription, you may owe an additional fee for the additional users. |
| Seats owed | If your maximum seats used exceeds the seats in your subscription, you'll owe an additional fee for the users you've added. |
| Subscription start date | Date your subscription started. If this is for a Free plan, is the date you transitioned off your group's paid plan. |
| Subscription end date | Date your current subscription will end. Does not apply to Free plans. |

## Renew your subscription

To renew your subscription, [prepare for the renewal](#prepare-for-renewal), then do one of the following:

- [Renew a GitLab.com subscription](#renew-or-change-a-gitlabcom-subscription).
- [Renew a self-managed subscription](#renew-a-self-managed-subscription).

### Prepare for renewal

The [Customers Portal](https://customers.gitlab.com/customers/sign_in) is your tool for renewing and modifying your subscription. Before going ahead with renewal, log in and verify or update:

- The invoice contact details on the **My Account** page.
- The credit card on file in the **Payment Methods** page.

TIP: **Tip:**
Contact our [support team](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=360000071293) if you need assistance accessing the Customers Portal or if you need to change the contact person who manages your subscription.

Check who is accessing your system. Are there user accounts which are no longer active? It's important to regularly review your GitLab user accounts because:

- A GitLab subscription is based on the number of users. Renewing a subscription for too many users results in you paying more than you should. Attempting to renew a subscription for too few users will result in the renewal failing.
- Stale user accounts can be a security risk. A regular review helps reduce this risk.

#### Users over License

A GitLab subscription is valid for a specific number of users. For details, see [Choose the number of users](#choosing-the-number-of-users). If the active user count exceeds the number included in the subscription, known as the number of _users over license_, you must pay for the excess number of users either before renewal, or at the time of renewal. This is also known the _true up_ process.

##### Purchase additional seats for GitLab.com

There is no self-service option for purchasing additional seats. You must request a quotation from GitLab Sales. To do so, contact GitLab via our [support form](https://support.gitlab.com/hc/en-us/requests/new) and select **Licensing and Renewals Problems** from the menu.

The amount charged per seat is calculated by one of the following methods:

- If paid before renewal, the amount per seat is calculated on a prorated basis. For example, if the user was added 3 months before the end of the subscription period, the amount owing is calculated as: (3 / 12) x annual fee.
- If paid on renewal, the amount per seat is the standard annual fee.

##### Purchase additional users for self-managed

Self-managed instances can add users to a subscription any time during the subscription period. The cost of additional users added during the subscription period is prorated from the date of purchase through the end of the subscription period.

To add users to a subscription:

1. Log in to [Customers Portal](https://customers.gitlab.com/).
1. Select **Manage Purchases**.
1. Select **Add more seats**.
1. Enter the number of additional users.
1. Select **Proceed to checkout**.
1. Review the **Subscription Upgrade Detail**. The system lists the total price for all users on the system and a credit for what you've already paid. You will only be charged for the net change.
1. Select **Confirm Upgrade**.

The following will be emailed to you:

- A payment receipt. You can also access this information in the Customers Portal under **Payment History**.
- A new license. [Upload this license](../user/admin_area/license.md#uploading-your-license) to your instance to use it.

### Renew or change a GitLab.com subscription

To renew for more users than are currently active in your GitLab.com system, contact our sales team via `renewals@gitlab.com` for assistance as this can't be done in Customers Portal.

To change the [GitLab tier](https://about.gitlab.com/pricing/), select **Upgrade** under your subscription on the [My Account](https://customers.gitlab.com/subscriptions) page.

#### Automatic renewal

To view or change automatic subscription renewal (at the same tier as the previous period), log in to the [Customers Portal](https://customers.gitlab.com/customers/sign_in), and:

- If you see a **Resume subscription** button, your subscription was cancelled previously. Click it to resume automatic renewal.
- If you see **Cancel subscription**, your subscription is set to automatically renew at the end of the subscription period. Click it to cancel automatic renewal.

With automatic renewal enabled, the subscription will automatically renew on the expiration date and there will be no gap in available service.
An invoice will be generated for the renewal and available for viewing or download in the [Payment History](https://customers.gitlab.com/receipts) page. If you have difficulty during the renewal process, contact our [support team](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=360000071293) for assistance.

### Renew a self-managed subscription

Starting 30 days before a subscription expires, GitLab notifies administrators of the date of expiry with a banner in the GitLab user interface.

We recommend following these steps during renewal:

1. Prune any inactive or unwanted users by [blocking them](../user/admin_area/blocking_unblocking_users.md#blocking-a-user).
1. Determine if you have a need for user growth in the upcoming subscription.
1. Log in to the [Customers Portal](https://customers.gitlab.com/customers/sign_in) and select the **Renew** button beneath your existing subscription.

   TIP: **Tip:**
   If you need to change your [GitLab tier](https://about.gitlab.com/pricing/), contact our sales team via `renewals@gitlab.com` for assistance as this can't be done in Customers Portal.

1. In the first box, enter the total number of user licenses you’ll need for the upcoming year. Be sure this number is at least **equal to, or greater than** the number of active users in the system at the time of performing the renewal.
1. Enter the number of [users over license](#users-over-license) in the second box for the user overage incurred in your previous subscription term.

   TIP: **Tip:**
   You can find the _users over license_ in your instance's **Admin** dashboard by clicking on {**admin**} (**Admin Area**) in the top bar, or going to `/admin`.

1. Review your renewal details and complete the payment process.
1. A license for the renewal term will be available on the [Manage Purchases](https://customers.gitlab.com/subscriptions) page beneath your new subscription details.
1. [Upload](../user/admin_area/license.md) your new license to your instance.

An invoice will be generated for the renewal and available for viewing or download in the [Payment History](https://customers.gitlab.com/receipts) page. If you have difficulty during the renewal process, contact our [support team](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=360000071293) for assistance.

## Subscription expiry

When your subscription or trial expires, GitLab does not delete your data, but it may become inaccessible, depending on the tier at expiry. Some features may not behave as expected if you're not prepared for the expiry. For example, [environment specific variables not being passed](https://gitlab.com/gitlab-org/gitlab/issues/24759).

If you renew or upgrade, your data will again be accessible.

### Self-managed GitLab data

For self-managed customers, there is a two-week grace period when your features
will continue to work as-is, after which the entire instance will become read
only.

However, if you remove the license, you will immediately revert to Core
features, and the instance will be read / write again.

## CI pipeline minutes

CI pipeline minutes are the execution time for your [pipelines](../ci/pipelines.md) on GitLab's shared runners. Each [GitLab.com tier](https://about.gitlab.com/pricing/) includes a monthly quota of CI pipeline minutes.

Quotas apply to:

- Groups, where the minutes are shared across all members of the group, its subgroups, and nested projects. To view the group's usage, navigate to the group's page, then **Settings > Usage Quotas**.
- Your personal account, where the minutes are available for your personal projects. To view and buy personal minutes, click your avatar, then **Settings > Pipeline quota**.

Only pipeline minutes for GitLab shared runners are restricted. If you have a specific runner set up for your projects, there is no limit to your build time on GitLab.com.

The minutes limit does not apply to public projects.

The available quota is reset on the first of each calendar month at midnight UTC.

When the CI minutes are depleted, an email is sent automatically to notify the owner(s)
of the group/namespace. You can [purchase additional CI minutes](#purchasing-additional-ci-minutes), or upgrade your account to [Silver or Gold](https://about.gitlab.com/pricing/). Your own runners can still be used even if you reach your limits.

### Purchasing additional CI minutes

If you're using GitLab.com, you can purchase additional CI minutes so your
pipelines won't be blocked after you have used all your CI minutes from your
main quota. Additional minutes:

- Are only used once the shared quota included in your subscription runs out.
- Roll over month to month.

To purchase additional minutes for your group on GitLab.com:

1. From your group, go to **Settings > Pipeline quota**.
1. Locate the subscription card that's linked to your group on GitLab.com, click **Buy more CI minutes**, and complete the details about the transaction.
1. Once we have processed your payment, the extra CI minutes will be synced to your group.
1. To confirm the available CI minutes, go to **Group > Settings > Pipelines quota**.  
   The **Additional minutes** displayed now includes the purchased additional CI minutes, plus any minutes rolled over from last month.

To purchase additional minutes for your personal namespace:

1. Click your avatar, then go to **Settings > Pipeline quota**.
1. Locate the subscription card that's linked to your personal namespace on GitLab.com, click **Buy more CI minutes**, and complete the details about the transaction. Once we have processed your payment, the extra CI minutes will be synced to your Group.
1. To confirm the available CI minutes for your personal projects, click your avatar, then go to **Settings > Pipeline quota**.  
   The **Additional minutes** displayed now includes the purchased additional CI minutes, plus any minutes rolled over from last month.

Be aware that:

- If you have purchased extra CI minutes before the purchase of a paid plan,
  we will calculate a pro-rated charge for your paid plan. That means you may
  be charged for less than one year since your subscription was previously
  created with the extra CI minutes.
- Once the extra CI minutes has been assigned to a Group they can't be transferred
  to a different Group.
- If you have used more minutes than your default quota, these minutes will
  be deducted from your Additional Minutes quota immediately after your purchase of additional
  minutes.

## Contact Support

We also encourage all users to search our project trackers for known issues and
existing feature requests in the [GitLab](https://gitlab.com/gitlab-org/gitlab/issues/) project.

These issues are the best avenue for getting updates on specific product plans
and for communicating directly with the relevant GitLab team members.

Learn more about:

- The tiers of [GitLab Support](https://about.gitlab.com/support/).
- [Submit a request via the Support Portal](https://support.gitlab.com/hc/en-us/requests/new).

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, e.g. `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
