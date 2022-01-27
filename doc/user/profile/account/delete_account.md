---
type: howto
stage: Manage
group: Authentication and Authorization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Deleting a User account **(FREE)**

Users can be deleted from a GitLab instance, either by:

- The user themselves.
- An administrator.

NOTE:
Deleting a user deletes all projects in that user namespace.

## As a user

As a user, to delete your own account:

1. On the top bar, in the top right corner, select your avatar.
1. Select **Edit profile**.
1. On the left sidebar, select **Account**.
1. Select **Delete account**.

## As an administrator **(FREE SELF)**

As an administrator, to delete a user account:

1. On the top bar, select **Menu > Admin**.
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

### Associated records

> - [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/7393) for issues in GitLab 9.0.
> - [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/10467) for merge requests, award emoji, notes, and abuse reports in GitLab 9.1.
> - [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/10273) hard deletion from abuse reports and spam logs in GitLab 9.1.
> - [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/11853) hard deletion from the API in GitLab 9.3.

There are two options for deleting users:

- **Delete user**
- **Delete user and contributions**

When using the **Delete user** option, not all associated records are deleted with the user.
Here's a list of things created by the user that are **not** deleted:

- Abuse reports
- Award emoji
- Epics
- Issues
- Merge requests
- Notes

Instead of being deleted, these records are moved to a system-wide
user with the username "Ghost User", whose sole purpose is to act as a container
for such records. Any commits made by a deleted user still display the
username of the original user.

When using the **Delete user and contributions** option, **all** associated records
are removed. This includes all of the items mentioned above including issues,
merge requests, notes/comments, and more. Consider
[blocking a user](../../admin_area/moderate_users.md#block-a-user)
or using the **Delete user** option instead.

When a user is deleted from an [abuse report](../../admin_area/review_abuse_reports.md)
or spam log, these associated
records are not ghosted and are removed, along with any groups the user
is a sole owner of. Administrators can also request this behavior when
deleting users from the [API](../../../api/users.md#user-deletion) or the
Admin Area.

## Troubleshooting

### Deleting a user results in a PostgreSQL null value error

There is [a known issue](https://gitlab.com/gitlab-org/gitlab/-/issues/349411) that results
in users not being deleted, and the following error generated:

```plaintext
ERROR: null value in column "user_id" violates not-null constraint
```

The error can be found in the [PostgreSQL log](../../../administration/logs.md#postgresql-logs) and
in the **Retries** section of the [background jobs view](../../admin_area/index.md#background-jobs) in the Admin Area.

If the user being deleted used the [iterations](../../group/iterations/index.md) feature, such
as adding an issue to an iteration, you must use
[the workaround documented in the issue](https://gitlab.com/gitlab-org/gitlab/-/issues/349411#workaround)
to delete the user.
