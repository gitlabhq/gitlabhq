---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Delete users
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Users can be deleted from a GitLab instance, either by:

- The user themselves.
- An administrator.

{{< alert type="note" >}}

Deleting a user deletes all projects in that user namespace.

{{< /alert >}}

## Delete your own account

{{< details >}}

- Offering: GitLab.com, GitLab Self-Managed

{{< /details >}}

{{< history >}}

- Delay between a user deleting their own account and deletion of the user record introduced in GitLab 16.0 [with a flag](../../../administration/feature_flags/_index.md) named `delay_delete_own_user`. Enabled by default on GitLab.com.

{{< /history >}}

{{< alert type="note" >}}

On GitLab Self-Managed, this feature is disabled by default. Use the
[application settings API](../../../api/settings.md) to enable the
`delay_user_account_self_deletion` setting for the instance.

{{< /alert >}}

You can schedule your account for deletion. When you delete your account, it enters a pending
deletion state. Generally, deletions happen in an hour, but can take up to seven days for
accounts that are either:

- Associated with comments, issues, merge requests, notes, or snippets
- Not part of a paid plan

While your account is pending deletion:

- Your account is [blocked](../../../administration/moderate_users.md#block-a-user).
- You cannot create a new account with the same username.
- You cannot create a new account with the same primary email address unless you change the
  email address first.

{{< alert type="note" >}}

After the account is deleted, any user can create a user account with the same username. If
another user takes the username, you cannot reclaim it.

{{< /alert >}}

To delete your own account:

1. On the left sidebar, select your avatar. If you've [turned on the new navigation](../../interface_redesign.md#turn-new-navigation-on-or-off), this button is in the upper-right corner.
1. Select **Edit profile**.
1. On the left sidebar, select **Account**.
1. Select **Delete account**.

If you cannot delete your account on GitLab.com, submit a [personal data request](https://support.gitlab.io/personal-data-request/)
to remove your account and data from GitLab.

## Delete users and user contributions

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Prerequisites:

- You must be an administrator for the instance.

To delete a user:

1. On the left sidebar, at the bottom, select **Admin**. If you've [turned on the new navigation](../../interface_redesign.md#turn-new-navigation-on-or-off), in the upper-right corner, select your avatar and then select **Admin**.
1. Select **Overview** > **Users**.
1. Select a user.
1. Under the **Account** tab, select:
   - **Delete user** to delete only the user but maintain their [associated records](#associated-records). You can't use this option if
     the selected user is the sole owner of any groups.
   - **Delete user and contributions** to delete the user and their associated records. This option also removes all groups (and
     projects within these groups) where the user is the sole direct Owner of a group. Inherited ownership doesn't apply.

{{< alert type="warning" >}}

Using the **Delete user and contributions** option may result in removing more data than intended. See
[associated records](#associated-records) for additional details.

{{< /alert >}}

### Associated records

When deleting users, you can either:

- Delete just the user, but move contributions to a system-wide "Ghost User":
  - The `@ghost` acts as a container for all deleted users' contributions.
  - The user's profile and personal projects are deleted, instead of moved to the Ghost User.
- Delete the user and their contributions, including:
  - Abuse reports.
  - Emoji reactions.
  - Groups of which the user is the only user with the Owner role.
  - Personal access tokens.
  - Epics.
  - Issues.
  - Merge requests.
  - Snippets.
  - [Notes and comments](../../../api/notes.md)
    on other users' [commits](../../project/repository/_index.md#commit-changes-to-a-repository),
    [epics](../../group/epics/_index.md),
    [issues](../../project/issues/_index.md),
    [merge requests](../../project/merge_requests/_index.md)
    and [snippets](../../snippets.md).

In both cases, commits retain [user information](https://git-scm.com/book/en/v2/Git-Internals-Git-Objects#_git_commit_objects)
and therefore data integrity within a [Git repository](../../project/repository/_index.md).

An alternative to deleting is [blocking a user](../../../administration/moderate_users.md#block-a-user).

When a user is deleted from an [abuse report](../../../administration/review_abuse_reports.md) or spam log, these associated
records are always removed.

The deleting associated records option can be requested in the [API](../../../api/users.md#delete-a-user) as well as
the **Admin** area.

{{< alert type="warning" >}}

User approvals are associated with a user ID. Other user contributions do not have an associated user ID. When you delete a user and their contributions are moved to a "Ghost User", the approval contributions refer to a missing or invalid user ID. Instead of deleting users, consider [blocking](../../../administration/moderate_users.md#block-a-user), [banning](../../../administration/moderate_users.md#ban-a-user), or [deactivating](../../../administration/moderate_users.md#deactivate-a-user) them.

{{< /alert >}}

## Delete the root account on a GitLab Self-Managed instance

{{< details >}}

- Offering: GitLab Self-Managed

{{< /details >}}

{{< alert type="warning" >}}

The root account is the most privileged account on the system. Deleting the root account might result in losing access to the instance [**Admin** area](../../../administration/admin_area.md) if there is no other administrator available on the instance.

{{< /alert >}}

You can delete the root account using either the UI or the [GitLab Rails console](../../../administration/operations/rails_console.md).

Before you delete the root account:

1. If you have created any [project](../../project/settings/project_access_tokens.md) or [personal access tokens](../personal_access_tokens.md) for the root account and use them in your workflow, transfer any necessary permissions or ownership from the root account to the new administrator.
1. [Back up your GitLab Self-Managed instance](../../../administration/backup_restore/backup_gitlab.md).
1. Consider [deactivating](../../../administration/moderate_users.md#deactivate-a-user) or [blocking](../../../administration/moderate_users.md#block-and-unblock-users) the root account instead.

### Use the UI

Prerequisites:

- You must be an administrator for the GitLab Self-Managed instance.

To delete the root account:

1. In the **Admin** area, [create a new user with administrator access](create_accounts.md#create-a-user-in-the-admin-area). This ensures that you maintain administrator access to the instance whilst mitigating the risks associated with deleting the root account.
1. [Delete the root account](#delete-users-and-user-contributions).

### Use the GitLab Rails console

{{< alert type="warning" >}}

Commands that change data can cause damage if not run correctly or under the right conditions. Always run commands in a test environment first and have a backup instance ready to restore.

{{< /alert >}}

Prerequisites:

- You must have access to the GitLab Rails console.

To delete the root account, in the Rails console:

1. Give another existing user administrator access:

   ```ruby
   user = User.find(username: 'Username') # or use User.find_by(email: 'email@example.com') to find by email
   user.admin = true
   user.save!
   ```

   This ensures that you maintain administrator access to the instance whilst mitigating the risks associated with deleting the root account.

1. To delete the root account, do either of the following:

   - Block the root account:

     ```ruby
     # This needs to be a current admin user
     current_user = User.find(username: 'Username')

     # This is the root user we want to block
     user = User.find(username: 'Username')

     ::Users::BlockService.new(current_user).execute(user)
     ```

   - Deactivate the root user:

     ```ruby
     # This needs to be a current admin user
     current_user = User.find(username: 'Username')

     # This is the root user we want to deactivate
     user = User.find(username: 'Username')

     ::Users::DeactivateService.new(current_user, skip_authorization: true).execute(user)
     ```

## Troubleshooting

### Deleting a user results in a PostgreSQL null value error

There is [a known issue](https://gitlab.com/gitlab-org/gitlab/-/issues/349411) that results
in users not being deleted, and the following error generated:

```plaintext
ERROR: null value in column "user_id" violates not-null constraint
```

The error can be found in the [PostgreSQL log](../../../administration/logs/_index.md#postgresql-logs) and
in the **Retries** section of the [background jobs view](../../../administration/admin_area.md#background-jobs) in the **Admin** area.

If the user being deleted used the [iterations](../../group/iterations/_index.md) feature, such
as adding an issue to an iteration, you must use
[the workaround documented in the issue](https://gitlab.com/gitlab-org/gitlab/-/issues/349411#workaround)
to delete the user.
