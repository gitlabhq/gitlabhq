---
stage: Fulfillment
group: Subscription management
description: Seat assignment, GitLab Duo Pro add-on
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Subscription add-ons

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

You can purchase subscription add-ons to give users in your organization access to more GitLab features.
Subscription add-ons are purchased as additional seats in your subscription.
Access to features provided by subscription add-ons is managed through seat assignment. Subscription
add-ons can be assigned to billable users only.

## Purchase GitLab Duo Pro seats

You can purchase additional GitLab Duo Pro seats for your group namespace or self-managed instance. After you complete the purchase,
you must assign the seats to billable users so that they can use GitLab Duo Pro.

To purchase GitLab Duo Pro seats, you can use the Customers Portal, or you can contact the [GitLab Sales team](https://about.gitlab.com/solutions/gitlab-duo-pro/sales/).

1. Sign in to the [GitLab Customers Portal](https://customers.gitlab.com/).
1. On the subscription card, select the vertical ellipsis (**{ellipsis_v}**).
1. Select **Buy GitLab Duo Pro**.
1. Enter the number of seats for GitLab Duo Pro.
1. Review the **Purchase summary** section.
1. From the **Payment method** dropdown list, select your payment method.
1. Select **Purchase seats**.

## Assign GitLab Duo Pro seats

Prerequisites:

- You must purchase the GitLab Duo Pro add-on.
- For self-managed and GitLab Dedicated, the GitLab Duo Pro add-on is available for GitLab 16.8 and later only.

After you purchase GitLab Duo Pro, you can assign seats to billable users to grant access to the add-on.

### For GitLab.com

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > Usage Quotas**.
1. Select the **GitLab Duo Pro** tab.
1. To the right of the user, turn on the toggle to assign GitLab Duo Pro.

To use Code Suggestions in any project or group, a user must be assigned a seat in at least one top-level group.

### For self-managed

Prerequisites:

- You must be an administrator.

1. On the left sidebar, at the bottom, select **Admin Area**.
1. Select **GitLab Duo Pro**.
   - If the **GitLab Duo Pro** menu item is not available, synchronize your subscription
   after purchase:
     1. On the left sidebar, select **Subscription**.
     1. In **Subscription details**, to the right of **Last sync**, select
     synchronize subscription (**{retry}**).
1. To the right of the user, turn on the toggle to assign GitLab Duo Pro.

#### Configure network and proxy settings

For all self-managed AI features:

- Your firewalls and HTTP/S proxy servers must allow outbound connections
  to `gitlab.com` and `cloud.gitlab.com` on port `443`.
- Both `HTTP2` and the `'upgrade'` header must be allowed, because GitLab Duo
  uses both REST and WebSockets.
- To use an HTTP/S proxy, both `gitLab_workhorse` and `gitLab_rails` must have the necessary
  [web proxy environment variables](https://docs.gitlab.com/omnibus/settings/environment-variables.html) set.
- Check for restrictions on WebSocket (`wss://`) traffic to `wss://gitlab.com/-/cable` and other `.com` domains.
  Network policy restrictions on `wss://` traffic can cause issues with some GitLab Duo Chat
  services. Consider policy updates to allow these services.

### Assign seats in bulk

To assign seats in bulk, you can use [this GraphQL API endpoint](../api/graphql/reference/index.md#mutationuseraddonassignmentcreate).

This endpoint works for both self-managed and SaaS.

Administrators of self-managed instances can also assign users by using a [Rake task](../raketasks/user_management.md#bulk-assign-users-to-gitlab-duo-pro).

## Purchase additional GitLab Duo Pro seats

You can purchase additional GitLab Duo Pro seats for your group namespace or self-managed instance. After you complete the purchase, the seats are added to the total number of GitLab Duo Pro seats in your subscription.

Prerequisites:

- You must purchase the GitLab Duo Pro add-on.

### For GitLab.com

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > Usage Quotas**.
1. Select the **GitLab Duo Pro** tab.
1. Select **Add seats**.
1. In the Customers Portal, in the **Add additional seats** field, enter the number of seats. The amount
   cannot be higher than the number of seats in the subscription associated with your group namespace.
1. In the **Billing information** section, select the payment method from the dropdown list.
1. Select the **Privacy Policy** and **Terms of Service** checkbox.
1. Select **Purchase seats**.
1. Select the **GitLab SaaS** tab and refresh the page.

### For self-managed and GitLab Dedicated

Prerequisites:

- You must be an administrator.

1. Sign in to the [GitLab Customers Portal](https://customers.gitlab.com/).
1. On the **GitLab Duo Pro** section of your subscription card click **Add seats** button.
1. Enter the number of seats. The amount cannot be higher than the number of seats in the subscription.
1. Review the **Purchase summary** section.
1. From the **Payment method** dropdown list, select your payment method.
1. Select **Purchase seats**.

## Start GitLab Duo Pro trial

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

### On GitLab.com

Prerequisites:

- You must have an active paid Premium or Ultimate subscription.

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > Billing**.
1. Select **Start a free GitLab Duo Pro trial**.
1. Complete the fields.
1. Select **Continue**.
1. If prompted, select the group that the trial should be applied to.
1. Select **Activate my trial**.
1. [Assign seats](#assign-gitlab-duo-pro-seats) to the users who need access.

### On Self-managed and GitLab Dedicated

Prerequisites:

- You must have an active paid Premium or Ultimate subscription.
- You must have GitLab 16.8 or later and your instance must be able to [synchronize your subscription data](self_managed/index.md#subscription-data-synchronization) with GitLab.
- The user who registers for the trial must be listed as the [subscription contact](customers_portal.md#change-your-subscription-contact) for the customer account and use same email address associated with that role.

1. Find your subscription ID:
   - In the Customers Portal, on the **Subscriptions & purchases** page.
   - In the email sent after you purchased your subscription.

   The ID usually looks like `A-S00123456`.
1. Go to the [GitLab Duo Pro trial page](http://about.gitlab.com/solutions/gitlab-duo-pro/self-managed-and-gitlab-dedicated-trial).
1. Complete the fields.
1. Select **Submit**.

The trial automatically syncs to your instance within 24 hours. After the trial has synced, [assign seats](#assign-gitlab-duo-pro-seats) to users that you want to access GitLab Duo Pro.
