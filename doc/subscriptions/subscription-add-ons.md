---
stage: Fulfillment
group: Provision
description: Seat assignment, GitLab Duo Pro add-on
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Subscription add-ons

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** SaaS, self-managed

You can purchase subscription add-ons to give users in your organization access to more GitLab features.
Subscription add-ons are purchased as additional seats in your subscription.
Access to features provided by subscription add-ons is managed through seat assignment. Subscription
add-ons can be assigned to billable users only.

## Assign GitLab Duo Pro seats

Prerequisites:

- You must purchase the GitLab Duo Pro add-on from the [GitLab Sales Team](https://about.gitlab.com/solutions/gitlab-duo-pro/sales/).
- For self-managed and GitLab Dedicated, the GitLab Duo Pro add-on is available for GitLab 16.8 and later only.

After you purchase GitLab Duo Pro, you can assign seats to billable users to grant access to the add-on.

### For GitLab.com

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > Usage Quotas**.
<!-- vale gitlab.Substitutions = NO -->
1. Select the **Duo Pro** tab.
<!-- vale gitlab.Substitutions = YES -->
1. To the right of the user, turn on the toggle to assign GitLab Duo Pro.

### For self-managed

Prerequisites:

- You must be an administrator.

1. On the left sidebar, at the bottom, select **Admin Area**.
<!-- vale gitlab.Substitutions = NO -->
1. Select **Duo Pro**.
   - If the **Duo Pro** menu item is not available, synchronize your subscription
   after purchase:
     1. On the left sidebar, select **Subscription**.
     1. In **Subscription details**, to the right of **Last sync**, select
     synchronize subscription (**{retry}**).
<!-- vale gitlab.Substitutions = YES -->
1. To the right of the user, turn on the toggle to assign GitLab Duo Pro.

### Assign seats in bulk

To assign seats in bulk, you can use [this GraphQL API endpoint](../api/graphql/reference/index.md#mutationuseraddonassignmentcreate).

This endpoint works for both self-managed and SaaS.

Administrators of self-managed instances can also assign users by using a [Rake task](../raketasks/user_management.md#bulk-assign-users-to-gitlab-duo-pro).

#### Configure network and proxy settings

For self-managed instances, you must also ensure that your firewalls and HTTP proxy servers
allow outbound connections to `cloud.gitlab.com`.

To use an HTTP proxy, ensure that both `gitLab _workhorse` and `gitLab_rails` set the necessary
[web proxy environment variables](https://docs.gitlab.com/omnibus/settings/environment-variables.html).
