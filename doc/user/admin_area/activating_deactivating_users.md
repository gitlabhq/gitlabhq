---
stage: Manage
group: Access
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
type: howto
---

# Activating and deactivating users

GitLab administrators can deactivate and activate users.

## Deactivating a user

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/22257) in GitLab 12.4.

In order to temporarily prevent access by a GitLab user that has no recent activity, administrators
can choose to deactivate the user.

Deactivating a user is functionally identical to [blocking a user](blocking_unblocking_users.md),
with the following differences:

- It does not prohibit the user from logging back in via the UI.
- Once a deactivated user logs back into the GitLab UI, their account is set to active.

A deactivated user:

- Cannot access Git repositories or the API.
- Will not receive any notifications from GitLab.
- Will not be able to use [slash commands](../../integration/slash_commands.md).

Personal projects, and group and user history of the deactivated user will be left intact.

A user can be deactivated from the Admin Area. To do this:

1. Navigate to  **Admin Area > Overview > Users**.
1. Select a user.
1. Under the **Account** tab, click **Deactivate user**.

Please note that for the deactivation option to be visible to an admin, the user:

- Must be currently active.
- Must not have any signins or activity in the last 180 days.

Users can also be deactivated using the [GitLab API](../../api/users.md#deactivate-user).

NOTE: **Note:**
A deactivated user does not consume a [seat](../../subscriptions/index.md#choosing-the-number-of-users).

## Activating a user

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/22257) in GitLab 12.4.

A deactivated user can be activated from the Admin Area.

To do this:

1. Navigate to  **Admin Area > Overview > Users**.
1. Click on the **Deactivated** tab.
1. Select a user.
1. Under the **Account** tab, click **Activate user**.

Users can also be activated using the [GitLab API](../../api/users.md#activate-user).

NOTE: **Note:**
Activating a user will change the user's state to active and it consumes a
[seat](../../subscriptions/index.md#choosing-the-number-of-users).

TIP: **Tip:**
A deactivated user can also activate their account themselves by simply logging back in via the UI.
