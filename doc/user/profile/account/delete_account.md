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
