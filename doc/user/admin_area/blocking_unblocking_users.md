---
stage: Manage
group: Access
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: howto
---

# Blocking and unblocking users

GitLab administrators block and unblock users.

## Blocking a user

In order to completely prevent access of a user to the GitLab instance, administrators can choose to
block the user.

Users can be blocked [via an abuse report](abuse_reports.md#blocking-users),
or directly from the Admin Area. To do this:

1. Navigate to  **Admin Area > Overview > Users**.
1. Select a user.
1. Under the **Account** tab, click **Block user**.

A blocked user:

- Cannot log in.
- Cannot access Git repositories or the API.
- Does not receive any notifications from GitLab.
- Cannot use [slash commands](../../integration/slash_commands.md).

Personal projects, and group and user history of the blocked user are left intact.

Users can also be blocked using the [GitLab API](../../api/users.md#block-user).

NOTE: **Note:**
A blocked user does not consume a [seat](../../subscriptions/self_managed/index.md#billable-users).

## Unblocking a user

A blocked user can be unblocked from the Admin Area. To do this:

1. Navigate to  **Admin Area > Overview > Users**.
1. Click on the **Blocked** tab.
1. Select a user.
1. Under the **Account** tab, click **Unblock user**.

Users can also be unblocked using the [GitLab API](../../api/users.md#unblock-user).

NOTE: **Note:**
Unblocking a user changes the user's state to active and consumes a
[seat](../../subscriptions/self_managed/index.md#billable-users).
