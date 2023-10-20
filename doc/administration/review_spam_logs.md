---
stage: Govern
group: Anti-Abuse
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
type: reference, howto
---

# Review spam logs **(FREE SELF)**

GitLab tracks user activity and flags certain behavior for potential spam.

In the Admin Area, a GitLab administrator can view and resolve spam logs.

## Manage spam logs

> **Trust user** [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/131812) in GitLab 16.5.

View and resolve spam logs to moderate user activity in your instance.

To view spam logs:

1. On the left sidebar, select **Search or go to**.
1. Select **Admin Area**.
1. Select **Spam Logs**.
1. Optional. To resolve a spam log, select a log and then select **Remove user**, **Block user**, **Remove log**, or **Trust user**.

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

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, for example `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
