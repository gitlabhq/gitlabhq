---
type: howto
stage: Manage
group: Access
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Deleting a User account

Users can be deleted from a GitLab instance, either by:

- The user themselves.
- An administrator.

NOTE:
Deleting a user deletes all projects in that user namespace.

## As a user

As a user, to delete your own account:

1. In the top-right corner, select your avatar.
1. Select **Edit profile**.
1. In the left sidebar, select **Account**.
1. Select **Delete account**.

## As an administrator

As an administrator, to delete a user account:

1. On the top bar, select **Menu >** **{admin}** **Admin**.
1. On the left sidebar, select **Overview > Users**.
1. Select a user.
1. Under the **Account** tab, select:
   - **Delete user** to delete only the user but maintain their
     [associated records](#associated-records).
   - **Delete user and contributions** to delete the user and
     their associated records.

WARNING:
Using the **Delete user and contributions** option may result
in removing more data than intended. Please see [associated records](#associated-records)
below for additional details.

## Associated Records

> - Introduced for issues in [GitLab 9.0](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/7393).
> - Introduced for merge requests, award emoji, notes, and abuse reports in [GitLab 9.1](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/10467).
> - Hard deletion from abuse reports and spam logs was introduced in [GitLab 9.1](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/10273), and from the API in [GitLab 9.3](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/11853).

There are two options for deleting users:

- **Delete user**
- **Delete user and contributions**

When using the **Delete user** option, not all associated records are deleted with the user.
Here's a list of things that are **not** deleted:

- Issues that the user created.
- Merge requests that the user created.
- Notes that the user created.
- Abuse reports that the user reported.
- Award emoji that the user created.

Instead of being deleted, these records are moved to a system-wide
user with the username "Ghost User", whose sole purpose is to act as a container
for such records. Any commits made by a deleted user still display the
username of the original user.

When using the **Delete user and contributions** option, **all** associated records
are removed. This includes all of the items mentioned above including issues,
merge requests, notes/comments, and more. Consider
[blocking a user](../../admin_area/moderate_users.md#blocking-a-user)
or using the **Delete user** option instead.

When a user is deleted from an [abuse report](../../admin_area/review_abuse_reports.md)
or spam log, these associated
records are not ghosted and are removed, along with any groups the user
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
