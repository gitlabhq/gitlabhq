---
stage: Anti-Abuse
group: Anti-Abuse
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Git abuse rate limit **(ULTIMATE)**

> [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/8066) in GitLab 15.2 [with a flag](../../../administration/feature_flags.md) named `limit_unique_project_downloads_per_namespace_user`. Disabled by default.

FLAG:
On self-managed GitLab, by default this feature is not available. To make it available, ask an administrator to [enable the feature flag](../../../administration/feature_flags.md) named `limit_unique_project_downloads_per_namespace_user`. On GitLab.com, this feature is available.

Git abuse rate limiting is a feature to automatically ban users who download or clone more than a specified number of repositories in a group or any of its subgroups within a given time frame. Banned users cannot access the main group or any of its non-public subgroups via HTTP or SSH. Access to unrelated groups is unaffected.

If the `limit_unique_project_downloads_per_namespace_user` feature flag is enabled, all users with the Owner role for the main group receive an email when a user is about to be banned.

If automatic banning is disabled, a user is not banned automatically when they exceed the limit. However, users with the Owner role for the main group are still notified. You can use this setup to determine the correct values of the rate limit settings before enabling automatic banning.

If automatic banning is enabled, users with the Owner role for the main group receive an email when a user is about to be banned, and the user is automatically banned from the group and its subgroups.

## Configure Git abuse rate limiting

1. On the left sidebar, select **Settings > Reporting**.
1. Update the Git abuse rate limit settings:
   1. Enter a number in the **Number of repositories** field, greater than or equal to `0` and less than or equal to `10,000`. This number specifies the maximum amount of unique repositories a user can download in the specified time period before they're banned. When set to `0`, Git abuse rate limiting is disabled.
   1. Enter a number in the **Reporting time period (seconds)** field, greater than or equal to `0` and less than or equal to `86,400` (10 days). This number specifies the time in seconds a user can download the maximum amount of repositories before they're banned. When set to `0`, Git abuse rate limiting is disabled.
   1. Optional. Exclude up to `100` users by adding them to the **Excluded users** field. Excluded users are not automatically banned.
   1. Optional. Turn on the **Automatically ban users from this namespace when they exceed the specified limits** toggle to enable automatic banning.
1. Select **Save changes**.

## Unban a user

Prerequisites:

- You must have the Owner role.

1. On the left sidebar, select **Group information > Members**.
1. Select the **Banned** tab.
1. For the account you want to unban, select **Unban**.
