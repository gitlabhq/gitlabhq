---
stage: Software Supply Chain Security
group: Authorization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Git abuse rate limit (administration)
---

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab Self-Managed

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/8066) in GitLab 15.2 [with a flag](../feature_flags.md) named `git_abuse_rate_limit_feature_flag`. Disabled by default.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/394996) in GitLab 15.11. Feature flag `git_abuse_rate_limit_feature_flag` removed.

This is the administration documentation. For information about Git abuse rate limiting for a group, see the [group documentation](../../user/group/reporting/git_abuse_rate_limit.md).

Git abuse rate limiting is a feature to automatically [ban users](../moderate_users.md#ban-and-unban-users) who download, clone, or fork more than a specified number of repositories in any project in the instance in a given time frame. Banned users cannot sign in to the instance and cannot access any non-public group via HTTP or SSH. The rate limit also applies to users who authenticate with a [personal](../../user/profile/personal_access_tokens.md) or [group access token](../../user/group/settings/group_access_tokens.md).

Git abuse rate limiting does not apply to instance administrators, [deploy tokens](../../user/project/deploy_tokens/_index.md), or [deploy keys](../../user/project/deploy_keys/_index.md).

How GitLab determines a user's rate limit is under development.
GitLab team members can view more information in this confidential epic:
`https://gitlab.com/groups/gitlab-org/modelops/anti-abuse/-/epics/14`.

## Configure Git abuse rate limiting

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > Reporting**.
1. Expand **Git abuse rate limit**.
1. Update the Git abuse rate limit settings:
   1. Enter a number in the **Number of repositories** field, greater than or equal to `0` and less than or equal to `10,000`. This number specifies the maximum amount of unique repositories a user can download in the specified time period before they're banned. When set to `0`, Git abuse rate limiting is disabled.
   1. Enter a number in the **Reporting time period (seconds)** field, greater than or equal to `0` and less than or equal to `86,400` (10 days). This number specifies the time in seconds a user can download the maximum amount of repositories before they're banned. When set to `0`, Git abuse rate limiting is disabled.
   1. Optional. Exclude up to `100` users by adding them to the **Excluded users** field. Excluded users are not automatically banned.
   1. Add up to `100` users to the **Send notifications to** field. You must select at least one user. All application administrators are selected by default.
   1. Optional. Turn on the **Automatically ban users from this namespace when they exceed the specified limits** toggle to enable automatic banning.
1. Select **Save changes**.

## Automatic ban notifications

If automatic banning is disabled, a user is not banned automatically when they exceed the limit. However, notifications are still sent to the users listed under **Send notifications to**. You can use this setup to determine the correct values of the rate limit settings before enabling automatic banning.

If automatic banning is enabled, an email notification is sent when a user is about to be banned, and the user is automatically banned from the GitLab instance.

## Unban a user

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Overview > Users**.
1. Select the **Banned** tab and search for the account you want to unban.
1. From the **User administration** dropdown list select **Unban user**.
1. On the confirmation dialog, select **Unban user**.
