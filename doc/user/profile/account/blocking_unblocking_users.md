---
type: howto
---

# Blocking and unblocking users

## Blocking a user

Inorder to completely prevent access of a user to the GitLab instance, admin can choose to block the user.

Users can be blocked [via an abuse report](../../admin_area/abuse_reports.md#blocking-users),
or directly from the Admin area. To do this:

1. Navigate to  **Admin Area > Overview > Users**.
1. Select a user.
1. Under the **Account** tab, click **Block user**.

A blocked user:

- Will not be able to login.
- Cannot access Git repositories or the API.
- Will not receive any notifications from GitLab.
- Will not be able to use [slash commands](../../../integration/slash_commands.md).

Personal projects, group and user history of the blocked user will be left intact.

Users can also be blocked using the [GitLab API](../../../api/users.html#block-user).

NOTE: **Note:**
A blocked user does not consume a [seat](../../../subscriptions/index.md#managing-subscriptions).

## Unblocking a user

A blocked user can be unblocked from the Admin area. To do this:

1. Navigate to  **Admin Area > Overview > Users**.
1. Click on the **Blocked** tab.
1. Select a user.
1. Under the **Account** tab, click **Unblock user**.

Users can also be unblocked using the [GitLab API](../../../api/users.html#unblock-user).

NOTE: **Note:**
Unblocking a user will change the user's state to active and it consumes a [seat](../../../subscriptions/index.md#managing-subscriptions).
