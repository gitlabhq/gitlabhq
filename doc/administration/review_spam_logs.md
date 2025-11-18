---
stage: Software Supply Chain Security
group: Authorization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
gitlab_dedicated: yes
title: Review spam logs
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

GitLab tracks user activity and flags certain behavior for potential spam.

In the **Admin** area, a GitLab administrator can view and resolve spam logs.

## Manage spam logs

{{< history >}}

- **Trust user** [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/131812) in GitLab 16.5.

{{< /history >}}

View and resolve spam logs to moderate user activity in your instance.

To view spam logs:

1. On the left sidebar, at the bottom, select **Admin**. If you've [turned on the new navigation](../user/interface_redesign.md#turn-new-navigation-on-or-off), in the upper-right corner, select **Admin**.
1. Select **Spam logs**.
1. Optional. To resolve a spam log, select **More actions** ({{< icon name="ellipsis_v" >}}), then **Remove user**, **Block user**, **Remove log**, or **Trust user**.

### Resolving spam logs

You can resolve a spam log with one of the following effects:

| Option | Description |
|---------|-------------|
| **Remove user** | The user is [deleted](../user/profile/account/delete_account.md) from the instance. |
| **Block user** | The user is blocked from the instance. The spam log remains in the list. |
| **Remove log** | The spam log is removed from the list. |
| **Trust user** | The user is trusted, and can create issues, notes, snippets, and merge requests without being blocked for spam. Spam logs are not created for trusted users. |

## Related topics

- [Moderate users (administration)](moderate_users.md)
- [Review abuse reports](review_abuse_reports.md)
