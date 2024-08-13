---
stage: Govern
group: Anti-Abuse
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Review spam logs

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** Self-managed

GitLab tracks user activity and flags certain behavior for potential spam.

In the **Admin** area, a GitLab administrator can view and resolve spam logs.

## Manage spam logs

> - **Trust user** [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/131812) in GitLab 16.5.

View and resolve spam logs to moderate user activity in your instance.

To view spam logs:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Spam logs**.
1. Optional. To resolve a spam log, select **More actions** (**{ellipsis_v}**), then **Remove user**, **Block user**, **Remove log**, or **Trust user**.

### Resolving spam logs

You can resolve a spam log with one of the following effects:

| Option | Description |
|---------|-------------|
| **Remove user** | The user is [deleted](../user/profile/account/delete_account.md) from the instance. |
| **Block user** | The user is blocked from the instance. The spam log remains in the list. |
| **Remove log** | The spam log is removed from the list. |
| **Trust user** | The user is trusted, and can create issues, notes, snippets, and merge requests without being blocked for spam. Spam logs are not created for trusted users. |

NOTE:
Users can be [blocked](../api/users.md#block-user) and
[unblocked](../api/users.md#unblock-user) using the GitLab API.
