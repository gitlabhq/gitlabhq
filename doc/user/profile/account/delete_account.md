---
type: howto
---

# Deleting a User account

Users can be deleted from a GitLab instance, either by:

- The user themselves.
- An administrator.

NOTE: **Note:**
Deleting a user will delete all projects in that user namespace.

## As a user

As a user, you can delete your own account by:

1. Clicking on your avatar.
1. Navigating to **Settings > Account**.
1. Selecting **Delete account**.

## As an administrator

As an administrator, you can delete a user account by:

1. Navigating to **Admin Area > Overview > Users**.
1. Selecting a user.
1. Under the **Account** tab, clicking:
   - **Delete user** to delete only the user but maintaining their
     [associated records](#associated-records).
   - **Delete user and contributions** to delete the user and
     their associated records.

### Blocking a user

In addition to blocking a user
[via an abuse report](../../admin_area/abuse_reports.md#blocking-users),
a user can be blocked directly from the Admin area. To do this:

1. Navigate to  **Admin Area > Overview > Users**.
1. Selecting a user.
1. Under the **Account** tab, click **Block user**.

### Deactivating a user

> [Introduced](https://gitlab.com/gitlab-org/gitlab-ce/issues/63921) in GitLab 12.4.

A user can be deactivated from the Admin area. Deactivating a user is functionally identical to blocking a user, with the following differences:

- It does not prohibit the user from logging back in via the UI.
- Once a deactivated user logs back into the GitLab UI, their account is set to active.

A deactivated user:

- Cannot access Git repositories or the API.
- Will not receive any notifications from GitLab.
- Will not be able to use [slash commands](../../../integration/slash_commands.md).

Personal projects, group and user history of the deactivated user will be left intact.

NOTE: **Note:**
A deactivated user does not consume a [seat](../../../subscriptions/index.md#managing-subscriptions).

To do this:

1. Navigate to  **Admin Area > Overview > Users**.
1. Select a user.
1. Under the **Account** tab, click **Deactivate user**.

Please note that for the deactivation option to be visible to an admin, the user:

- Must be currently active.
- Should not have any activity in the last 14 days.

### Activating a user

> [Introduced](https://gitlab.com/gitlab-org/gitlab-ce/issues/63921) in GitLab 12.4.

A deactivated user can be activated from the Admin area. Activating a user sets their account to active state.

To do this:

1. Navigate to  **Admin Area > Overview > Users**.
1. Click on the **Deactivated** tab.
1. Select a user.
1. Under the **Account** tab, click **Activate user**.

TIP: **Tip:**
A deactivated user can also activate their account by themselves by simply logging back via the UI.

## Associated Records

> - Introduced for issues in
>   [GitLab 9.0](https://gitlab.com/gitlab-org/gitlab-foss/merge_requests/7393).
> - Introduced for merge requests, award emoji, notes, and abuse reports in
>   [GitLab 9.1](https://gitlab.com/gitlab-org/gitlab-foss/merge_requests/10467).
> - Hard deletion from abuse reports and spam logs was introduced in
>   [GitLab 9.1](https://gitlab.com/gitlab-org/gitlab-foss/merge_requests/10273),
>   and from the API in
>   [GitLab 9.3](https://gitlab.com/gitlab-org/gitlab-foss/merge_requests/11853).

When a user account is deleted, not all associated records are deleted with it.
Here's a list of things that will **not** be deleted:

- Issues that the user created.
- Merge requests that the user created.
- Notes that the user created.
- Abuse reports that the user reported.
- Award emoji that the user created.

Instead of being deleted, these records will be moved to a system-wide
user with the username "Ghost User", whose sole purpose is to act as a container
for such records. Any commits made by a deleted user will still display the
username of the original user.

When a user is deleted from an [abuse report](../../admin_area/abuse_reports.md)
or spam log, these associated
records are not ghosted and will be removed, along with any groups the user
is a sole owner of. Administrators can also request this behavior when
deleting users from the [API](../../../api/users.md#user-deletion) or the
Admin Area.

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, e.g. `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
