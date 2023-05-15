---
type: howto
stage: Manage
group: Authentication and Authorization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Deleting a user account **(FREE)**

Users can be deleted from a GitLab instance, either by:

- The user themselves.
- An administrator.

NOTE:
Deleting a user deletes all projects in that user namespace.

## Delete your own account

As a user, to delete your own account:

1. On the top bar, in the upper-right corner, select your avatar.
1. Select **Edit profile**.
1. On the left sidebar, select **Account**.
1. Select **Delete account**.

## Delete users and user contributions **(FREE SELF)**

As an administrator, to delete a user account:

1. On the top bar, select **Main menu > Admin**.
1. On the left sidebar, select **Overview > Users**.
1. Select a user.
1. Under the **Account** tab, select:
   - **Delete user** to delete only the user but maintain their [associated records](#associated-records). You can't use this option if
     the selected user is the sole owner of any groups.
   - **Delete user and contributions** to delete the user and their associated records. This option also removes all groups (and
     projects within these groups) where the user is the sole direct Owner of a group. Inherited ownership doesn't apply.

WARNING:
Using the **Delete user and contributions** option may result in removing more data than intended. See
[associated records](#associated-records) for additional details.

### Associated records

When deleting users, you can either:

- Delete just the user. Not all associated records are deleted with the user. Instead of being deleted, these records
  are moved to a system-wide user with the username Ghost User. The Ghost User's purpose is to act as a container for
  such records. Any commits made by a deleted user still display the username of the original user.
  The user's personal projects are deleted, not moved to the Ghost User.
- Delete the user and their contributions, including:
  - Abuse reports.
  - Emoji reactions.
  - Epics.
  - Groups of which the user is the only user with the Owner role.
  - Issues.
  - Merge requests.
  - Notes and comments.
  - Personal access tokens.
  - Snippets.

An alternative to deleting is [blocking a user](../../admin_area/moderate_users.md#block-a-user).

When a user is deleted from an [abuse report](../../admin_area/review_abuse_reports.md) or spam log, these associated
records are always removed.

The deleting associated records option can be requested in the [API](../../../api/users.md#user-deletion) as well as
the Admin Area.

## Troubleshooting

### Deleting a user results in a PostgreSQL null value error

There is [a known issue](https://gitlab.com/gitlab-org/gitlab/-/issues/349411) that results
in users not being deleted, and the following error generated:

```plaintext
ERROR: null value in column "user_id" violates not-null constraint
```

The error can be found in the [PostgreSQL log](../../../administration/logs/index.md#postgresql-logs) and
in the **Retries** section of the [background jobs view](../../admin_area/index.md#background-jobs) in the Admin Area.

If the user being deleted used the [iterations](../../group/iterations/index.md) feature, such
as adding an issue to an iteration, you must use
[the workaround documented in the issue](https://gitlab.com/gitlab-org/gitlab/-/issues/349411#workaround)
to delete the user.
