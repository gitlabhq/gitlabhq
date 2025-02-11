---
stage: Software Supply Chain Security
group: Authorization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Git abuse rate limit
---

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab.com, GitLab Self-Managed

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/8066) in GitLab 15.2 [with a flag](../../../administration/feature_flags.md) named `limit_unique_project_downloads_per_namespace_user`. Disabled by default.

FLAG:
The availability of this feature is controlled by a feature flag.
For more information, see the history.

This is the group-level documentation. For self-managed instances, see the [administration documentation](../../../administration/reporting/git_abuse_rate_limit.md).

Git abuse rate limiting is a feature to automatically ban users who download, clone, pull, fetch, or fork more than a specified number of repositories of a group in a given time frame. Banned users cannot access the top-level group or any of its non-public subgroups through HTTP or SSH. The rate limit also applies to users who authenticate with [personal](../../profile/personal_access_tokens.md) or [group access tokens](../settings/group_access_tokens.md), as well as [CI/CD job tokens](../../../ci/jobs/ci_job_token.md). Access to unrelated groups is unaffected.

Git abuse rate limiting does not apply to top-level group owners, [deploy tokens](../../project/deploy_tokens/_index.md), or [deploy keys](../../project/deploy_keys/_index.md).

How GitLab determines a user's rate limit is under development.
GitLab team members can view more information in this confidential epic:
`https://gitlab.com/groups/gitlab-org/modelops/anti-abuse/-/epics/14`.

## Automatic ban notifications

If the `limit_unique_project_downloads_per_namespace_user` feature flag is enabled, selected users receive an email when a user is about to be banned.

If automatic banning is disabled, a user is not banned automatically when they exceed the limit. However, notifications are still sent. You can use this setup to determine the correct values of the rate limit settings before enabling automatic banning.

If automatic banning is enabled, an email notification is sent when a user is about to be banned, and the user is automatically banned from the group and its subgroups.

## Configure Git abuse rate limiting

1. On the left sidebar, select **Settings > Reporting**.
1. Update the Git abuse rate limit settings:
   1. Enter a number in the **Number of repositories** field, greater than or equal to `0` and less than or equal to `10,000`. This number specifies the maximum amount of unique repositories a user can download in the specified time period before they're banned. When set to `0`, Git abuse rate limiting is disabled.
   1. Enter a number in the **Reporting time period (seconds)** field, greater than or equal to `0` and less than or equal to `86,400` (10 days). This number specifies the time in seconds a user can download the maximum amount of repositories before they're banned. When set to `0`, Git abuse rate limiting is disabled.
   1. Optional. Exclude up to `100` users by adding them to the **Excluded users** field. Excluded users are not automatically banned.
   1. Add up to `100` users to the **Send notifications to** field. You must select at least one user. All users with the Owner role for the main group are selected by default.
   1. Optional. Turn on the **Automatically ban users from this namespace when they exceed the specified limits** toggle to enable automatic banning.
1. Select **Save changes**.

## Related topics

- [Ban and unban users](../moderate_users.md).
