---
stage: Anti-Abuse
group: Anti-Abuse
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Git abuse rate limit **(ULTIMATE SELF)**

> [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/8066) in GitLab 15.2 [with flags](../../../administration/feature_flags.md) named `git_abuse_rate_limit_feature_flag` and `auto_ban_user_on_excessive_projects_download`. Both flags are disabled by default.

FLAG:
On self-managed GitLab, by default this feature is not available. To make it available, ask an administrator to [enable the feature flags](../../../administration/feature_flags.md) named `git_abuse_rate_limit_feature_flag` and `auto_ban_user_on_excessive_projects_download`.

Git abuse rate limiting is a feature to automatically [ban users](../moderate_users.md#ban-and-unban-users) who download more than a specified number of repositories in a given time. When the `git_abuse_rate_limit_feature_flag` feature flag is enabled, the administrator receives an email when a user is about to be banned.

When the `auto_ban_user_on_excessive_projects_download` is not enabled, the user is not banned automatically. You can use this setup to determine the correct values of the rate limit settings.

When both flags are enabled, the administrator receives an email when a user is about to be banned, and the user is automatically banned from the GitLab instance.

## Configure Git abuse rate limiting

1. On the top bar, select **Menu > Admin**.
1. On the left sidebar, select **Settings > Reporting**.
1. Expand **Git abuse rate limit**.
1. Update the Git abuse rate limit settings:
   1. Enter a number in the **Number of repositories** field, greater than or equal to `0` and less than or equal to `10,000`. This number specifies the maximum amount of unique repositories a user can download in the specified time period before they're banned. When set to `0`, Git abuse rate limiting is disabled.
   1. Enter a number in the **Reporting time period (seconds)** field, greater than or equal to `0` and less than or equal to `86,400`. This number specifies the time in seconds a user can download the maximum amount of repositories before they're banned. When set to `0`, Git abuse rate limiting is disabled.
   1. Optional. Exclude users by adding them to the **Excluded users** field. Excluded users are not automatically banned.
1. Select **Save changes**.
